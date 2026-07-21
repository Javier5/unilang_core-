local ESX = exports['es_extended']:getSharedObject()

local PlayerData = {
    Cooldowns = {},
    Hygiene = {},
    Needs = {},
    Diseases = {},
    HealthStates = {} -- Nueva tabla para: bleeding, open_wound, poisoned
}

local METADATA_KEYS = {
    HYGIENE = 'bathroom_cleanliness',
    BLADDER = 'bathroom_bladder',
    BOWEL = 'bathroom_bowel',
    DISEASES = 'bathroom_diseases',
    HEALTH_STATES = 'bathroom_health_states'
}

-- [[ INICIALIZACIÓN MEJORADA ]] ------------------------------------
AddEventHandler('esx:playerLoaded', function(source, xPlayer)
    local src = source
    PlayerData.Hygiene[src] = { level = xPlayer.getMetadata(METADATA_KEYS.HYGIENE) or 100, notified = {} }
    PlayerData.Needs[src] = { bladder = xPlayer.getMetadata(METADATA_KEYS.BLADDER) or 0, bowel = xPlayer.getMetadata(METADATA_KEYS.BOWEL) or 0 }
    PlayerData.Diseases[src] = xPlayer.getMetadata(METADATA_KEYS.DISEASES) or {}
    PlayerData.HealthStates[src] = xPlayer.getMetadata(METADATA_KEYS.HEALTH_STATES) or { bleeding = false, wound = false, poisoned = false }
    PlayerData.Cooldowns[src] = {}
    
    TriggerClientEvent('esx_bathroom:client:initializeNeeds', src, {
        bladder = PlayerData.Needs[src].bladder,
        bowel = PlayerData.Needs[src].bowel,
        hygiene = PlayerData.Hygiene[src].level
    })
end)

-- [[ GESTIÓN DE ESTADOS DE SALUD (NUEVO) ]] --------------------------
RegisterServerEvent('esx_bathroom:updateHealthState')
AddEventHandler('esx_bathroom:updateHealthState', function(state, value)
    local src = source
    if PlayerData.HealthStates[src] then
        PlayerData.HealthStates[src][state] = value
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then xPlayer.setMetadata(METADATA_KEYS.HEALTH_STATES, PlayerData.HealthStates[src]) end
    end
end)

-- [[ LÓGICA DE ACCIONES (CORREGIDA) ]] -------------------------------
RegisterServerEvent('esx_bathroom:finishAction')
AddEventHandler('esx_bathroom:finishAction', function(actionType)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not Config.Effects[actionType] then return end

    -- Validar cooldown con lógica corregida
    local now = GetGameTimer()
    if PlayerData.Cooldowns[src][actionType] and now < PlayerData.Cooldowns[src][actionType] then return end
    
    local effects = Config.Effects[actionType]
    
    -- Aplicar efectos
    if effects.cleanliness_gain then
        local newHyg = math.min(100, PlayerData.Hygiene[src].level + effects.cleanliness_gain)
        PlayerData.Hygiene[src].level = newHyg
        xPlayer.setMetadata(METADATA_KEYS.HYGIENE, newHyg)
    end

    -- Limpieza de estados (Ducha/Lavabo cura heridas y sangrado)
    if actionType == 'shower' or actionType == 'sink' then
        PlayerData.HealthStates[src] = { bleeding = false, wound = false, poisoned = false }
        xPlayer.setMetadata(METADATA_KEYS.HEALTH_STATES, PlayerData.HealthStates[src])
        TriggerClientEvent('esx_bathroom:client:removeDiseaseEffect', src, 'all')
    end

    -- Resetear necesidades
    if actionType == 'toilet' or actionType == 'urinal' then
        PlayerData.Needs[src].bladder = 0
        PlayerData.Needs[src].bowel = 0
        xPlayer.setMetadata(METADATA_KEYS.BLADDER, 0)
        xPlayer.setMetadata(METADATA_KEYS.BOWEL, 0)
    end

    PlayerData.Cooldowns[src][actionType] = now + (Config.Cooldowns[actionType] * 1000)
    TriggerClientEvent('esx:showNotification', src, '✅ Acción completada')
end)

AddEventHandler('esx:playerDropped', function(src)
    PlayerData.Cooldowns[src] = nil
    PlayerData.Hygiene[src] = nil
    PlayerData.Needs[src] = nil
    PlayerData.Diseases[src] = nil
    PlayerData.HealthStates[src] = nil
end)
-- [[ LIMPIEZA AL MORIR ]] -------------------------------------------
AddEventHandler('esx:onPlayerDeath', function(data)
    local src = source
    if PlayerData.HealthStates[src] then
        -- Resetear estados críticos al morir
        PlayerData.HealthStates[src] = { bleeding = false, wound = false, poisoned = false }
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then xPlayer.setMetadata(METADATA_KEYS.HEALTH_STATES, PlayerData.HealthStates[src]) end
        
        -- Detener efectos visuales (moscas)
        TriggerClientEvent('esx_bathroom:client:removeDiseaseEffect', src, 'all')
    end
end)
