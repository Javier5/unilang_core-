-- ================================================================= --
--                        CLIENT.LUA MEJORADO & CORREGIDO            --
--         SISTEMA AVANZADO DE HIGIENE Y NECESIDADES              --
-- ================================================================= --

local ESX = exports['es_extended']:getSharedObject()
local ActionTimestamps = {}
local isActionInProgress = false
local isNearObject = false
local currentZone = nil
local ptfxHandle = 0
local smellPtfxHandle = 0
local needsUpdateTimer = 0

local playerNeeds = {
    bladder = 0,
    bowel = 0,
    hygiene = 100
}

-- Optimization caches for NPC reaction loop
local smellAnimLoaded = false
local smellAnimDict = "anim@mp_player_intupper@smell"
local pedReactCooldowns = {} -- [ped] = timestamp

-- Response holder for server-side shop validation
local canInteractResult = nil

-- [[ INICIALIZACIÓN CONFIGURADA ]] ----------------------------------
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    ESX.PlayerData = xPlayer
end)

Citizen.CreateThread(function()
    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(100)
    end

    StartNeedsSystem()
    if Config.Debug then
        print('[ESX_BATHROOM] Cliente inicializado correctamente - Sistema de necesidades enlazado')
    end
end)

-- [[ SINCRONIZACIÓN CON METADATA DEL SERVIDOR ]] --------------------
RegisterNetEvent('esx_bathroom:client:initializeNeeds')
AddEventHandler('esx_bathroom:client:initializeNeeds', function(data)
    if data then
        playerNeeds.bladder = data.bladder or 0
        playerNeeds.bowel = data.bowel or 0
        playerNeeds.hygiene = data.hygiene or 100
        if Config.Debug then
            print(string.format('[SINCRONIZACIÓN] Vejiga: %d%%, Intestinos: %d%%, Higiene: %d%%', playerNeeds.bladder, playerNeeds.bowel, playerNeeds.hygiene))
        end
    end
end)

-- [[ SISTEMA DE NECESIDADES FISIOLÓGICAS ]] ------------------------
function StartNeedsSystem()
    Citizen.CreateThread(function()
        needsUpdateTimer = GetGameTimer()
        while true do
            Citizen.Wait(5000)
            local currentTime = GetGameTimer()
            if currentTime - needsUpdateTimer >= (Config.NeedsSystem.updateInterval or 30000) then
                if Config.NeedsSystem.enabled and not isActionInProgress then
                    playerNeeds.bladder = math.min(100, playerNeeds.bladder + (Config.NeedsSystem.bladderIncrease or 2))
                    playerNeeds.bowel = math.min(100, playerNeeds.bowel + (Config.NeedsSystem.bowelIncrease or 1))
                    if Config.Debug then
                        print(string.format('[NECESIDADES PASIVAS] Vejiga: %d%%, Intestinos: %d%%', playerNeeds.bladder, playerNeeds.bowel))
                    end
                end
                needsUpdateTimer = currentTime
            end

            if not isActionInProgress then
                CheckNeedsEffects()
            end
        end
    end)
end

function CheckNeedsEffects()
    for threshold, effect in pairs(Config.NeedsSystem.effects.bladder) do
        if playerNeeds.bladder >= threshold then
            ESX.ShowNotification(effect.message)
            break
        end
    end

    for threshold, effect in pairs(Config.NeedsSystem.effects.bowel) do
        if playerNeeds.bowel >= threshold then
            ESX.ShowNotification(effect.message)
            break
        end
    end
end

-- [[ SISTEMA DE DETECCIÓN OPTIMIZADO ]] -------------------------------
Citizen.CreateThread(function()
    while true do
        local waitTime = 500
        local playerPed = PlayerPedId()

        if not isActionInProgress and not IsPedInAnyVehicle(playerPed, false) then
            local playerCoords = GetEntityCoords(playerPed)
            local closestZone = nil
            local closestDist = (Config.DrawDistance or 2.5) + 1.0

            for i = 1, #Config.Locations do
                local zone = Config.Locations[i]
                local dist = #(playerCoords - zone.coords)
                if dist < closestDist then
                    closestDist = dist
                    closestZone = zone
                end
            end

            if closestZone and closestDist <= (Config.DrawDistance or 2.5) then
                waitTime = 0
                local actionConfig = Config.Actions[closestZone.type]
                if actionConfig then
                    DrawText3DImproved(closestZone.coords, actionConfig.text)
                    if not isNearObject then
                        isNearObject = true
                        currentZone = closestZone
                    end

                    if IsControlJustReleased(0, Config.InteractKey or 38) then
                        if not IsActionOnCooldown(currentZone.type) then
                            OpenInteractionMenu(currentZone)
                        else
                            local remaining = GetCooldownRemaining(currentZone.type)
                            ESX.ShowNotification('⏰ Debes esperar ' .. remaining .. ' segundos para volver a usar este aparato.')
                        end
                    end
                end
            else
                if isNearObject then
                    isNearObject = false
                    currentZone = nil
                end
            end
        end

        Citizen.Wait(waitTime)
    end
end)

-- [[ TEXTO 3D ]] -----------------------------------------------------
function DrawText3DImproved(coords, text)
    local onScreen, screenX, screenY = World3dToScreen2d(coords.x, coords.y, coords.z + 1.0)
    if onScreen then
        local camCoords = GetGameplayCamCoords()
        local dist = #(camCoords - coords)
        local scale = (1 / dist) * 2
        local fov = (1 / GetGameplayCamFov()) * 100
        scale = scale * fov

        SetTextScale(0.0, 0.35 * scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(screenX, screenY)

        local keyText = "Presiona ~g~[E]~w~ para usar"
        SetTextScale(0.0, 0.25 * scale)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(keyText)
        DrawText(screenX, screenY + 0.025)
    end
end

-- [[ MENU ]] --------------------------------------------------------
function OpenInteractionMenu(zoneData)
    local elements = {}
    local actionConfig = Config.Actions[zoneData.type]

    if Config.NeedsSystem.enabled then
        table.insert(elements, { label = string.format('💧 Vejiga: %d%% | 💩 Intestino: %d%%', playerNeeds.bladder, playerNeeds.bowel), value = 'info' })
        table.insert(elements, { label = '──────────────────────────', value = 'separator' })
    end

    table.insert(elements, { label = '▶️ Iniciar Acción: ' .. actionConfig.text, value = zoneData.type })

    ESX.UI.Menu.CloseAll()
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'bathroom_interaction_menu', {
        title = '🧼 Control de Higiene',
        align = 'bottom-right',
        elements = elements,
    }, function(data, menu)
        if data.current.value ~= 'info' and data.current.value ~= 'separator' then
            menu.close()
            StartActionSequence(data.current.value, zoneData)
        end
    end, function(data, menu)
        menu.close()
    end)
end

-- [[ SECUENCIA DE ACCIÓN ]] ----------------------------------------
function StartActionSequence(actionType, zoneData)
    local actionConfig = Config.Actions[actionType]
    local playerPed = PlayerPedId()

    isActionInProgress = true
    ESX.UI.Menu.CloseAll()

    SetEntityCoords(playerPed, zoneData.coords.x, zoneData.coords.y, zoneData.coords.z - 0.95)
    SetEntityHeading(playerPed, zoneData.heading)
    FreezeEntityPosition(playerPed, true)

    if actionConfig.sound and actionConfig.sound.startName then
        PlaySoundFrontend(-1, actionConfig.sound.startName, actionConfig.sound.startSet, true)
    end

    if actionConfig.ptfx then
        StartParticleEffect(actionConfig.ptfx, zoneData.coords)
    end

    if actionConfig.isScenario then
        TaskStartScenarioInPlace(playerPed, actionConfig.scenario, 0, true)
    elseif actionConfig.animDict and actionConfig.animName then
        ESX.Streaming.RequestAnimDict(actionConfig.animDict, function()
            TaskPlayAnim(playerPed, actionConfig.animDict, actionConfig.animName, 8.0, -8.0, -1, 1, 0, false, false, false)
        end)
    end

    ShowProgressBar(actionConfig.text, actionConfig.duration)
    Citizen.Wait(actionConfig.duration)

    CleanupAction(actionConfig)
    TriggerServerEvent('esx_bathroom:finishAction', actionType)

    if actionType == 'toilet' then
        playerNeeds.bladder = 0
        playerNeeds.bowel = 0
    elseif actionType == 'urinal' then
        playerNeeds.bladder = 0
    end

    isActionInProgress = false
end

-- [[ PTFX ]] -------------------------------------------------------
function StartParticleEffect(ptfxConfig, coords)
    ESX.Streaming.RequestPtfxAsset(ptfxConfig.dict, function()
        UseParticleFxAssetNextCall(ptfxConfig.dict)
        ptfxHandle = StartParticleFxLoopedAtCoord(ptfxConfig.name, coords.x + ptfxConfig.offset.x, coords.y + ptfxConfig.offset.y, coords.z + ptfxConfig.offset.z, 0.0, 0.0, 0.0, ptfxConfig.scale or 1.0, false, false, false, false)
    end)
end

-- [[ PROGRESS BAR ]] ------------------------------------------------
function ShowProgressBar(text, duration)
    Citizen.CreateThread(function()
        local startTime = GetGameTimer()
        local endTime = startTime + duration
        while GetGameTimer() < endTime and isActionInProgress do
            local currentTime = GetGameTimer()
            local progress = (currentTime - startTime) / duration
            local percent = math.max(0, math.min(100, math.floor(progress * 100)))
            BeginTextCommandDisplayHelp('STRING')
            AddTextComponentSubstringPlayerName(string.format('🔄 %s (~g~%d%%~w~)', text, percent))
            EndTextCommandDisplayHelp(0, false, false, -1)
            Citizen.Wait(0)
        end
    end)
end

-- [[ LIMPIEZA ]] ---------------------------------------------------
function CleanupAction(actionConfig)
    local playerPed = PlayerPedId()
    if ptfxHandle ~= 0 then
        StopParticleFxLooped(ptfxHandle, false)
        ptfxHandle = 0
    end
    if smellPtfxHandle ~= 0 then
        StopParticleFxLooped(smellPtfxHandle, false)
        smellPtfxHandle = 0
    end
    if actionConfig.sound and actionConfig.sound.stopName then
        PlaySoundFrontend(-1, actionConfig.sound.stopName, actionConfig.sound.stopSet, true)
    end
    ClearPedTasksImmediately(playerPed)
    FreezeEntityPosition(playerPed, false)
end

-- [[ COOLDOWNS ]] --------------------------------------------------
function IsActionOnCooldown(actionType)
    local endTimestamp = ActionTimestamps[actionType]
    if endTimestamp then return GetGameTimer() < endTimestamp end
    return false
end

function GetCooldownRemaining(actionType)
    local endTimestamp = ActionTimestamps[actionType]
    if endTimestamp then return math.ceil((endTimestamp - GetGameTimer()) / 1000) end
    return 0
end

RegisterNetEvent('esx_bathroom:setCooldownClient')
AddEventHandler('esx_bathroom:setCooldownClient', function(actionType, cooldownEndTimestamp)
    ActionTimestamps[actionType] = cooldownEndTimestamp
end)

-- [[ ENFERMEDADES CLIENT ]] ----------------------------------------
RegisterNetEvent('esx_bathroom:client:applyDiseaseEffect')
AddEventHandler('esx_bathroom:client:applyDiseaseEffect', function(effects)
    if effects.stamina then
        SetPedMaxMoveBlendRatio(PlayerPedId(), 0.6)
    end
end)

RegisterNetEvent('esx_bathroom:client:removeDiseaseEffect')
AddEventHandler('esx_bathroom:client:removeDiseaseEffect', function(diseaseName)
    ResetPedMovementClipset(PlayerPedId(), 0.0)
    SetPedMaxMoveBlendRatio(PlayerPedId(), 1.0)
end)

-- [[ LIMPIEZA AL STOP ]] -------------------------------------------
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if ptfxHandle ~= 0 then StopParticleFxLooped(ptfxHandle, false) end
        if smellPtfxHandle ~= 0 then StopParticleFxLooped(smellPtfxHandle, false) end
        ClearPedTasksImmediately(PlayerPedId())
        FreezeEntityPosition(PlayerPedId(), false)
    end
end)

-- [[ DETECTOR DE DAÑO Y SANGRADO ]] --------------------------------
Citizen.CreateThread(function()
    local lastHealth = GetEntityHealth(PlayerPedId())
    while true do
        Citizen.Wait(1000)
        local playerPed = PlayerPedId()
        local currentHealth = GetEntityHealth(playerPed)
        if currentHealth < lastHealth then
            local damageTaken = lastHealth - currentHealth
            if damageTaken > 5 then
                TriggerServerEvent('esx_bathroom:updateHealthState', 'wound', true)
                if damageTaken > 20 then
                    TriggerServerEvent('esx_bathroom:updateHealthState', 'bleeding', true)
                    ESX.ShowNotification("🩸 ¡Estás sangrando! Necesitas detener la hemorragia.")
                end
            end
        end
        lastHealth = currentHealth
    end
end)

-- [[ EFECTOS DE SANGRE (placeholder) ]] -----------------------------
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2000)
    end
end)

-- [[ SISTEMA SOCIAL: REACCIÓN DE NPCS Y EFECTOS VISUALES ]] ---------
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.HygieneSystem.NPCCheckInterval or 1000)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local hygiene = playerNeeds.hygiene

        -- Partículas de moscas si higiene baja
        local smellConfig = Config.HygieneSystem.SmellPtfx or { dict = 'core', name = 'ent_amb_flies', offset = vector3(0.0,0.0,0.5), scale = 1.0 }
        if hygiene < (Config.HygieneSystem.SmellThreshold or 10) then
            if smellPtfxHandle == 0 then
                RequestNamedPtfxAsset(smellConfig.dict)
                while not HasNamedPtfxAssetLoaded(smellConfig.dict) do Citizen.Wait(0) end
                UseParticleFxAssetNextCall(smellConfig.dict)
                smellPtfxHandle = StartParticleFxLoopedOnEntity(smellConfig.name, playerPed, smellConfig.offset.x, smellConfig.offset.y, smellConfig.offset.z, 0.0, 0.0, 0.0, smellConfig.scale or 1.0, false, false, false)
            end
        else
            if smellPtfxHandle ~= 0 then
                StopParticleFxLooped(smellPtfxHandle, 0)
                smellPtfxHandle = 0
            end
        end

        -- Reacciones NPCs si higiene baja
        if hygiene < (Config.HygieneSystem.NPCReactThreshold or 20) then
            local nearbyPeds = GetGamePool('CPed')
            local maxDist = Config.HygieneSystem.NPCReactDistance or 5.0
            local maxDistSq = maxDist * maxDist
            local reacted = 0
            local maxPerTick = Config.HygieneSystem.NPCMaxReactPerTick or 6
            local reactCooldown = Config.HygieneSystem.NPCReactCooldownMs or 5000

            if not smellAnimLoaded then
                RequestAnimDict(smellAnimDict)
                while not HasAnimDictLoaded(smellAnimDict) do Citizen.Wait(0) end
                smellAnimLoaded = true
            end

            for _, ped in ipairs(nearbyPeds) do
                if reacted >= maxPerTick then break end
                if not IsPedAPlayer(ped) and not IsEntityDead(ped) then
                    local pedCoords = GetEntityCoords(ped)
                    local dx,dy,dz = playerCoords.x - pedCoords.x, playerCoords.y - pedCoords.y, playerCoords.z - pedCoords.z
                    local distSq = dx*dx + dy*dy + dz*dz
                    if distSq < maxDistSq then
                        local now = GetGameTimer()
                        if (not pedReactCooldowns[ped]) or (now - pedReactCooldowns[ped] >= reactCooldown) then
                            pedReactCooldowns[ped] = now
                            TaskPlayAnim(ped, smellAnimDict, "idle_a", 8.0, -8.0, 2000, 0, 0, false, false, false)
                            PlayAmbientSpeech1(ped, "GENERIC_HOWS_IT_GOING", "SPEECH_PARAMS_FORCE_NORMAL")
                            reacted = reacted + 1
                        end
                    end
                end
            end
        end
    end
end)

-- [[ RESTRICCIÓN COMERCIAL POR HIGIENE (CLIENT -> SERVER) ]] -------
RegisterNetEvent('esx_bathroom:server:canInteractResult')
AddEventHandler('esx_bathroom:server:canInteractResult', function(result)
    canInteractResult = result
end)

function CanInteractWithShop()
    -- Preguntar al servidor para evitar bypass
    canInteractResult = nil
    TriggerServerEvent('esx_bathroom:server:canInteractWithShop')
    local timeout = GetGameTimer() + 500
    while canInteractResult == nil and GetGameTimer() < timeout do Citizen.Wait(0) end
    if canInteractResult == nil then
        ESX.ShowNotification("~y~No se pudo verificar tu higiene, intenta de nuevo.")
        return false
    end
    return canInteractResult
end

-- [[ CURACIÓN MEDIANTE ÍTEMS ]] -------------------------------------
RegisterNetEvent('esx_bathroom:useAntidiarrheal')
AddEventHandler('esx_bathroom:useAntidiarrheal', function()
    TriggerServerEvent('esx_bathroom:updateHealthState', 'poisoned', false)
    ESX.ShowNotification("💊 Has tomado un anti-diarreico, te sientes mucho mejor.")
    TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_COP_IDLES", 0, true)
    Citizen.Wait(3000)
    ClearPedTasks(PlayerPedId())
end)

RegisterNetEvent('esx_bathroom:useWetWipes')
AddEventHandler('esx_bathroom:useWetWipes', function()
    TriggerServerEvent('esx_bathroom:updateHealthState', 'wound', false)
    TriggerServerEvent('esx_bathroom:updateHealthState', 'bleeding', false)
    ESX.ShowNotification("🧽 Te has limpiado rápidamente. La herida ya no está expuesta.")
    TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_MAID_CLEAN", 0, true)
    Citizen.Wait(3000)
    ClearPedTasks(PlayerPedId())
end)
