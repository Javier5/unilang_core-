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
local needsUpdateTimer = 0

local playerNeeds = {
    bladder = 0,    -- Vejiga (0-100)
    bowel = 0,      -- Intestinos (0-100)
    hygiene = 100   -- Higiene (0-100)
}

-- [[ INICIALIZACIÓN CONFIGURADA ]] ----------------------------------
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    ESX.PlayerData = xPlayer
end)

Citizen.CreateThread(function()
    -- Esperar a que el core de ESX cargue los datos del jugador de manera segura
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
            print(string.format('[SINCRONIZACIÓN] Datos cargados -> Vejiga: %d%%, Intestinos: %d%%, Higiene: %d%%', playerNeeds.bladder, playerNeeds.bowel, playerNeeds.hygiene))
        end
    end
end)

-- [[ SISTEMA DE NECESIDADES FISIOLÓGICAS ]] ------------------------
function StartNeedsSystem()
    Citizen.CreateThread(function()
        needsUpdateTimer = GetGameTimer()
        while true do
            Citizen.Wait(5000) -- Hilo de baja frecuencia (Cada 5 segundos de control)
            
            local currentTime = GetGameTimer()
            -- Actualizar e incrementar necesidades de forma pasiva local según el intervalo configurado
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
            
            -- Verificar los efectos de la acumulación de necesidades
            if not isActionInProgress then
                CheckNeedsEffects()
            end
        end
    end)
end

function CheckNeedsEffects()
    -- Alertas de Vejiga
    for threshold, effect in pairs(Config.NeedsSystem.effects.bladder) do
        if playerNeeds.bladder >= threshold then
            ESX.ShowNotification(effect.message)
            if effect.stress and effect.stress > 0 then
                -- Opcional: TriggerServerEvent('esx_status:add', 'stress', effect.stress * 100)
            end
            break
        end
    end
    
    -- Alertas de Intestino
    for threshold, effect in pairs(Config.NeedsSystem.effects.bowel) do
        if playerNeeds.bowel >= threshold then
            ESX.ShowNotification(effect.message)
            break
        end
    end
end

-- [[ SISTEMA DE DETECCIÓN OPTIMIZADO (0.00ms IDLE) ]] ---------------
Citizen.CreateThread(function()
    while true do
        local waitTime = 500 -- Frecuencia lenta cuando se está lejos de los puntos
        local playerPed = PlayerPedId()
        
        if not isActionInProgress and not IsPedInAnyVehicle(playerPed, false) then
            local playerCoords = GetEntityCoords(playerPed)
            local closestZone = nil
            local closestDist = Config.DrawDistance + 1.0

            -- Buscar zona más cercana mediante la optimización de magnitud nativa de vectores Lua (#)
            for i = 1, #Config.Locations do
                local zone = Config.Locations[i]
                local dist = #(playerCoords - zone.coords)
                
                if dist < closestDist then
                    closestDist = dist
                    closestZone = zone
                end
            end

            -- Activación de rango cercano
            if closestZone and closestDist <= Config.DrawDistance then
                waitTime = 0 -- Cambiar a renderizado en tiempo real (0ms)
                local actionConfig = Config.Actions[closestZone.type]
                
                if actionConfig then
                    DrawText3DImproved(closestZone.coords, actionConfig.text)
                    
                    if not isNearObject then
                        isNearObject = true
                        currentZone = closestZone
                    end

                    -- Manejar interacción de tecla E
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

-- [[ TEXTO 3D OPTIMIZADO Y RENDEREADO ]] ----------------------------
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

-- [[ MENÚ DE INTERACCIÓN INTEGRADO ]] -------------------------------
function OpenInteractionMenu(zoneData)
    local elements = {}
    local actionConfig = Config.Actions[zoneData.type]
    
    if Config.NeedsSystem.enabled then
        table.insert(elements, {
            label = string.format('💧 Vejiga: %d%% | 💩 Intestino: %d%%', playerNeeds.bladder, playerNeeds.bowel),
            value = 'info'
        })
        table.insert(elements, {label = '──────────────────────────', value = 'separator'})
    end

    table.insert(elements, {
        label = '▶️ Iniciar Acción: ' .. actionConfig.text,
        value = zoneData.type
    })

    ESX.UI.Menu.CloseAll()

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'bathroom_interaction_menu',
        {
            title    = '🧼 Control de Higiene',
            align    = 'bottom-right',
            elements = elements,
        },
        function(data, menu)
            if data.current.value ~= 'info' and data.current.value ~= 'separator' then
                menu.close()
                StartActionSequence(data.current.value, zoneData)
            end
        end,
        function(data, menu)
            menu.close()
        end
    )
end

-- [[ SECUENCIA DE ACCIÓN REESTRUCTURADA ]] -------------------------
function StartActionSequence(actionType, zoneData)
    local actionConfig = Config.Actions[actionType]
    local playerPed = PlayerPedId()
    
    isActionInProgress = true
    ESX.UI.Menu.CloseAll() -- Cerrar de forma única al iniciar la secuencia, no dentro del hilo recursivo de renderizado

    -- Posicionamiento forzado e inmersivo
    SetEntityCoords(playerPed, zoneData.coords.x, zoneData.coords.y, zoneData.coords.z - 0.95)
    SetEntityHeading(playerPed, zoneData.heading)
    FreezeEntityPosition(playerPed, true)
    
    -- Manejo del sistema de audios de GTA V
    if actionConfig.sound and actionConfig.sound.startName then
        PlaySoundFrontend(-1, actionConfig.sound.startName, actionConfig.sound.startSet, true)
    end
    
    -- Procesamiento de Efectos Visuales (Steam / Agua)
    if actionConfig.ptfx then
        StartParticleEffect(actionConfig.ptfx, zoneData.coords)
    end

    -- Ejecutar según las Flags del Config corregidas (isScenario vs AnimDict)
    if actionConfig.isScenario then
        TaskStartScenarioInPlace(playerPed, actionConfig.scenario, 0, true)
    elseif actionConfig.animDict and actionConfig.animName then
        ESX.Streaming.RequestAnimDict(actionConfig.animDict, function()
            TaskPlayAnim(playerPed, actionConfig.animDict, actionConfig.animName, 8.0, -8.0, -1, 1, 0, false, false, false)
        end)
    end
    
    -- Invocar barra de progreso segura
    ShowProgressBar(actionConfig.text, actionConfig.duration)

    -- Esperar de forma síncrona el tiempo de la animación
    Citizen.Wait(actionConfig.duration)

    -- Limpieza de entidades y variables de entorno
    CleanupAction(actionConfig)
    
    -- Comunicación sincrónica con el Servidor
    TriggerServerEvent('esx_bathroom:finishAction', actionType)
    
    -- Actualizar estado local inmediato post-acción
    if actionType == 'toilet' then
        playerNeeds.bladder = 0
        playerNeeds.bowel = 0
    elseif actionType == 'urinal' then
        playerNeeds.bladder = 0
    end
    
    isActionInProgress = false
end

-- [[ SISTEMA DE PARTÍCULAS SEGURO ]] -------------------------------
function StartParticleEffect(ptfxConfig, coords)
    ESX.Streaming.RequestPtfxAsset(ptfxConfig.dict, function()
        UseParticleFxAssetNextCall(ptfxConfig.dict)
        ptfxHandle = StartParticleFxLoopedAtCoord(
            ptfxConfig.name,
            coords.x + ptfxConfig.offset.x,
            coords.y + ptfxConfig.offset.y, 
            coords.z + ptfxConfig.offset.z,
            0.0, 0.0, 0.0,
            ptfxConfig.scale or 1.0,
            false, false, false, false
        )
    end)
end

-- [[ BARRA DE PROGRESO INDEPENDIENTE (SISTEMA FIX DE INTERFAZ) ]] --
function ShowProgressBar(text, duration)
    Citizen.CreateThread(function()
        local startTime = GetGameTimer()
        local endTime = startTime + duration
        
        while GetGameTimer() < endTime and isActionInProgress do
            local currentTime = GetGameTimer()
            local progress = (currentTime - startTime) / duration
            local percent = math.max(0, math.min(100, math.floor(progress * 100)))
            
            -- Renderizado por HelpText nativo limpio sin colapsar el ESX.UI.Menu
            BeginTextCommandDisplayHelp('STRING')
            AddTextComponentSubstringPlayerName(string.format('🔄 %s (~g~%d%%~w~)', text, percent))
            EndTextCommandDisplayHelp(0, false, false, -1)
            
            Citizen.Wait(0)
        end
    end)
end

-- [[ LIMPIEZA DE ACCIONES ]] -----------------------------------------
function CleanupAction(actionConfig)
    local playerPed = PlayerPedId()
    
    if ptfxHandle ~= 0 then
        StopParticleFxLooped(ptfxHandle, false)
        ptfxHandle = 0
    end
    
    if actionConfig.sound and actionConfig.sound.stopName then
        PlaySoundFrontend(-1, actionConfig.sound.stopName, actionConfig.sound.stopSet, true)
    end
    
    ClearPedTasksImmediately(playerPed)
    FreezeEntityPosition(playerPed, false)
end

-- [[ MANEJO DE COOLDOWNS ]] -----------------------------------------
function IsActionOnCooldown(actionType)
    local endTimestamp = ActionTimestamps[actionType]
    if endTimestamp then
        return GetGameTimer() < endTimestamp
    end
    return false
end

function GetCooldownRemaining(actionType)
    local endTimestamp = ActionTimestamps[actionType]
    if endTimestamp then
        return math.ceil((endTimestamp - GetGameTimer()) / 1000)
    end
    return 0
end

RegisterNetEvent('esx_bathroom:setCooldownClient')
AddEventHandler('esx_bathroom:setCooldownClient', function(actionType, cooldownEndTimestamp)
    ActionTimestamps[actionType] = cooldownEndTimestamp
end)

-- [[ MANEJO DE ENFERMEDADES EN CLIENTE ]] ----------------------------
RegisterNetEvent('esx_bathroom:client:applyDiseaseEffect')
AddEventHandler('esx_bathroom:client:applyDiseaseEffect', function(effects)
    -- Aquí puedes acoplar efectos como sacudidas de cámara o cansancio
    if effects.stamina then
        SetPedMaxMoveBlendRatio(PlayerPedId(), 0.6) -- Forzar a caminar lento por enfermedad
    end
end)

RegisterNetEvent('esx_bathroom:client:removeDiseaseEffect')
AddEventHandler('esx_bathroom:client:removeDiseaseEffect', function(diseaseName)
    ResetPedMovementClipset(PlayerPedId(), 0.0)
    SetPedMaxMoveBlendRatio(PlayerPedId(), 1.0)
end)

-- [[ EVENTOS DE LIMPIEZA DE MEMORIA ]] ------------------------------
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if ptfxHandle ~= 0 then StopParticleFxLooped(ptfxHandle, false) end
        ClearPedTasksImmediately(PlayerPedId())
        FreezeEntityPosition(PlayerPedId(), false)
    end
end)

-- [[ DETECTOR DE DAÑO Y SANGRAO ]] ----------------------------------
Citizen.CreateThread(function()
    local lastHealth = GetEntityHealth(PlayerPedId())
    
    while true do
        Citizen.Wait(1000) -- Revisión cada segundo para optimizar
        local playerPed = PlayerPedId()
        local currentHealth = GetEntityHealth(playerPed)
        
        if currentHealth < lastHealth then
            local damageTaken = lastHealth - currentHealth
            
            -- Si el daño es mayor a 5, marcamos herida abierta
            if damageTaken > 5 then
                TriggerServerEvent('esx_bathroom:updateHealthState', 'wound', true)
                
                -- Si el daño es mayor a 20, marcamos sangrado (bleeding)
                if damageTaken > 20 then
                    TriggerServerEvent('esx_bathroom:updateHealthState', 'bleeding', true)
                    ESX.ShowNotification("🩸 ¡Estás sangrando! Necesitas detener la hemorragia.")
                end
            end
        end
        
        lastHealth = currentHealth
    end
end)
-- [[ EFECTO VISUAL DE SANGRE ]] -------------------------------------
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2000) 
        -- Aquí podrías añadir un chequeo local si el jugador tiene la bandera 'bleeding'
        -- Si está sangrando, creamos el PTFX de sangre en los pies
        -- (Lo implementaremos en la siguiente fase de partículas)
    end
end)
-- [[ SISTEMA SOCIAL: REACCIÓN DE NPCS Y EFECTOS VISUALES ]] ----------------
Citizen.CreateThread(function()
    local ptfxHandle = nil

    while true do
        Citizen.Wait(1000) -- Hilo optimizado
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local hygiene = playerNeeds.hygiene -- Usamos la variable local de tu script

        -- 1. LÓGICA DE PARTÍCULAS (Moscas si higiene < 10%)
        if hygiene < 10 then
            if not ptfxHandle then
                RequestNamedPtfxAsset("core")
                while not HasNamedPtfxAssetLoaded("core") do Citizen.Wait(0) end
                UseParticleFxAssetNextCall("core")
                ptfxHandle = StartParticleFxLoopedOnEntity("ent_amb_flies", playerPed, 0.0, 0.0, 0.5, 0.0, 0.0, 0.0, 1.0, false, false, false)
            end
        else
            if ptfxHandle then
                StopParticleFxLooped(ptfxHandle, 0)
                ptfxHandle = nil
            end
        end

        -- 2. LÓGICA DE REACCIÓN DE NPCS (Si higiene < 20%)
        if hygiene < 20 then
            local nearbyPeds = GetGamePool('CPed')
            for _, ped in ipairs(nearbyPeds) do
                if not IsPedAPlayer(ped) and not IsEntityDead(ped) then
                    local pedCoords = GetEntityCoords(ped)
                    local dist = #(playerCoords - pedCoords)
                    
                    if dist < 5.0 then
                        -- El NPC se tapa la nariz y hace gesto de asco
                        RequestAnimDict("anim@mp_player_intupper@smell")
                        while not HasAnimDictLoaded("anim@mp_player_intupper@smell") do Citizen.Wait(0) end
                        
                        TaskPlayAnim(ped, "anim@mp_player_intupper@smell", "idle_a", 8.0, -8.0, 2000, 0, 0, false, false, false)
                        
                        -- Audio: Gesto de asco del NPC
                        PlayAmbientSpeech1(ped, "GENERIC_HOWS_IT_GOING", "SPEECH_PARAMS_FORCE_NORMAL")
                    end
                end
            end
        end
    end
end) 

-- [[ RESTRICCIÓN COMERCIAL POR HIGIENE ]] ---------------------------
-- Debes llamar a esta función antes de abrir cualquier menú de tienda
function CanInteractWithShop()
    local hygiene = playerNeeds.hygiene
    
    if hygiene < 20 then
        ESX.ShowNotification("🛑 Dependiente: '¡Ugh, qué mal hueles! No voy a atenderte así. Vete a darte una ducha.'")
        return false
    end
    return true
end

-- Ejemplo de uso (Aplicar en tu script de tiendas / esx_shops):
-- if CanInteractWithShop() then
--    OpenShopMenu()
-- else
--    -- Bloqueado
-- end

-- [[ CURACIÓN MEDIANTE ÍTEMS ]] -------------------------------------

-- 1. Anti-Diarreico: Elimina la intoxicación
RegisterNetEvent('esx_bathroom:useAntidiarrheal')
AddEventHandler('esx_bathroom:useAntidiarrheal', function()
    TriggerServerEvent('esx_bathroom:updateHealthState', 'poisoned', false)
    ESX.ShowNotification("💊 Has tomado un anti-diarreico, te sientes mucho mejor.")
    -- Animación opcional
    TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_COP_IDLES", 0, true)
    Citizen.Wait(3000)
    ClearPedTasks(PlayerPedId())
end)

-- 2. Toallitas Húmedas: Limpieza rápida de heridas/ropa (sin ducha)
RegisterNetEvent('esx_bathroom:useWetWipes')
AddEventHandler('esx_bathroom:useWetWipes', function()
    TriggerServerEvent('esx_bathroom:updateHealthState', 'wound', false)
    TriggerServerEvent('esx_bathroom:updateHealthState', 'bleeding', false)
    ESX.ShowNotification("🧽 Te has limpiado rápidamente. La herida ya no está expuesta.")
    -- Animación
    TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_MAID_CLEAN", 0, true)
    Citizen.Wait(3000)
    ClearPedTasks(PlayerPedId())
end)
