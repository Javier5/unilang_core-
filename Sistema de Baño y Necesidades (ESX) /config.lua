-- ================================================================= --
--                          CONFIG.LUA MEJORADO & CORREGIDO          --
--           SISTEMA AVANZADO DE HIGIENE Y NECESIDADES             --
-- ================================================================= --

Config = {}

-- [[ CONFIGURACIÓN GENERAL MEJORADA ]] --------------------------------
Config.Debug = false
Config.EnableAdvancedFeatures = true
Config.DrawDistance = 2.5
Config.InteractKey = 38 -- Tecla [E]
Config.ActionCooldown = 60 -- Cooldown por defecto si no se especifica (en segundos)

-- [[ SISTEMA DE NECESIDADES FISIOLÓGICAS ]] --------------------------
Config.NeedsSystem = {
    enabled = true,
    updateInterval = 30000, -- 30 segundos
    bladderIncrease = 2,    -- Aumento de vejiga por intervalo
    bowelIncrease = 1,      -- Aumento de intestinos por intervalo
    
    -- Efectos por necesidades no satisfechas
    effects = {
        bladder = {
            [80] = { stress = 10, message = "💦 Necesitas encontrar un baño pronto" },
            [95] = { stress = 25, message = "🚨 ¡URGENTE! Necesitas un baño YA" }
        },
        bowel = {
            [75] = { stress = 15, message = "💩 Sientes presión en el vientre" },
            [90] = { stress = 30, message = "🚨 ¡URGENTE! Necesitas un inodoro" }
        }
    }
}

-- [[ SISTEMA DE HIGIENE ]] -------------------------------------------
Config.HygieneSystem = {
    initialCleanliness = 80,
    maxCleanliness = 100,
    minCleanliness = 0,

    naturalDecay = {
        enabled = true,
        rate = 0.5,        -- Pérdida de higiene por intervalo
        interval = 60000   -- Cada 1 minuto
    },

    -- Umbrales y efectos (mantenidos)
    lowHygieneEffects = {
        [40] = { 
            message = "🤢 Te estás poniendo sucio...",
            socialPenalty = 0.1
        },
        [20] = { 
            message = "🤮 ¡Hueles mal! La gente empieza a notar tu aroma",
            socialPenalty = 0.3,
            healthEffect = 5 -- Reducción de esx_status
        },
        [10] = { 
            message = "💀 ¡HIGIENE CRÍTICA! Riesgo severo de enfermedades",
            socialPenalty = 0.5,
            healthEffect = 10,
            diseaseChance = 0.15 -- 15% de probabilidad
        }
    },

    -- ------------------------------------------------------------------
    -- Tunables para reacciones de NPC y efectos de olor (governability)
    -- ------------------------------------------------------------------
    NPCCheckInterval = 1000,           -- ms entre checks de NPC / PTFX
    NPCReactThreshold = 20,            -- higiene (%) por debajo de la cual reaccionan NPCs
    NPCReactDistance = 5.0,            -- distancia en metros para reaccionar
    NPCReactCooldownMs = 5000,         -- cooldown por NPC en ms
    NPCMaxReactPerTick = 6,            -- máximo NPCs a hacer reaccionar por tick

    -- PTFX de olor (moscas) y umbral
    SmellPtfx = {
        dict = 'core',
        name = 'ent_amb_flies',
        offset = vector3(0.0, 0.0, 0.5),
        scale = 1.0
    },
    SmellThreshold = 10,               -- higiene (%) por debajo de la cual aparecen moscas
    NPCCheckDistanceSqLock = true      -- dejar true usa squared distance optimizada
}

-- [[ EFECTOS DE ACCIONES ]] -------------------------------------------
Config.Effects = {
    toilet = {
        hunger_reduction = 0,
        thirst_reduction = 0,
        cleanliness_gain = 5,
        bladder_relief = 100, 
        bowel_relief = 100,   
        stress_relief = 20
    },
    urinal = {
        hunger_reduction = 0,
        thirst_reduction = 0,
        cleanliness_gain = 2,
        bladder_relief = 100,
        stress_relief = 10
    },
    shower = {
        cleanliness_gain = 60,
        hunger_reduction = 0,
        thirst_reduction = 0,
        stress_relief = 35,
        disease_prevention = true
    },
    sink = {
        cleanliness_gain = 15,
        hunger_reduction = 0,
        thirst_reduction = 0,
        stress_relief = 5,
        hand_hygiene = true
    }
}

-- [[ ANIMACIONES, SONIDOS Y PTFX (CORREGIDO) ]] -----------------------
Config.Actions = {
    toilet = {
        isScenario = true,
        scenario = 'PROP_HUMAN_SEAT_TOILET', 
        duration = 12000, 
        text = '🚽 Usando inodoro...',
        sound = {
            startName = 'FLUSH_WATER_SOUND',
            startSet = 'MP_AIRCRAFT_MISC_SOUNDS',
            stopName = 'TOILET_FLUSH',
            stopSet = 'MP_AIRCRAFT_MISC_SOUNDS'
        }
    },
    urinal = {
        isScenario = false,
        animDict = 'amb@world_human_peeing@male@base',
        animName = 'base',
        duration = 8000,
        text = '🚹 Usando orinal...',
        sound = {
            startName = 'WATER_TAP_ON',
            startSet = 'PI_PLANS_HEIST_PLANS_SOUNDSET',
            stopName = 'WATER_SHUT_OFF',
            stopSet = 'PI_PLANS_HEIST_PLANS_SOUNDSET'
        }
    },
    shower = {
        isScenario = false,
        animDict = 'mp_safehouseshower@male@',
        animName = 'action_a',
        duration = 15000, 
        text = '🚿 Tomando una ducha...',
        sound = {
            startName = 'FM_CUT_MICHAEL_SHOWER_START',
            startSet = 'MP_FM_CUTSCENES',
            stopName = 'WATER_SHUT_OFF',
            stopSet = 'PI_PLANS_HEIST_PLANS_SOUNDSET'
        },
        ptfx = {
            dict = 'core',
            name = 'ent_amb_shower_steam',
            offset = vector3(0.0, 0.0, 1.0),
            scale = 1.2
        }
    },
    sink = {
        isScenario = false,
        animDict = 'amb@world_human_wash_hands@male@base',
        animName = 'base',
        duration = 6000,
        text = '🚰 Lavándose las manos...',
        sound = {
            startName = 'WATER_TAP_ON',
            startSet = 'PI_PLANS_HEIST_PLANS_SOUNDSET',
            stopName = 'WATER_SHUT_OFF',
            stopSet = 'PI_PLANS_HEIST_PLANS_SOUNDSET'
        },
        ptfx = {
            dict = 'core',
            name = 'ent_amb_sink_tap_water_drip',
            offset = vector3(0.0, 0.2, 0.1)
        }
    }
}

-- [[ SISTEMA DE ENFERMEDADES ]] --------------------------------------
Config.DiseaseSystem = {
    enabled = true,
    diseases = {
        diarrhea = {
            chance = 0.15, 
            duration = 300000, -- 5 Minutos
            effects = { health = -20, stamina = -30 }
        },
        infection = {
            chance = 0.10, 
            duration = 600000, -- 10 Minutos
            effects = { health = -15, stress = 25 }
        }
    }
}

-- [[ UBICACIONES INTERACTIVAS CORREGIDAS ]] -------------------------
Config.Locations = {
    {
        coords = vector3(-1261.21, -1438.30, 4.40), 
        heading = 24.0,                            
        type = 'toilet',
        objectModel = 'prop_toilet_01',
        isPublic = true
    },
    {
        coords = vector3(-1262.50, -1438.90, 4.40), 
        heading = 24.0,
        type = 'urinal',
        objectModel = 'prop_urinal_01',
        isPublic = true
    },
    {
        coords = vector3(1832.15, 3690.25, 34.27), 
        heading = 210.0,
        type = 'toilet',
        objectModel = 'prop_toilet_01',
        isPublic = true
    },
    {
        coords = vector3(-1147.20, -685.20, 35.70), 
        heading = 330.0,
        type = 'shower',
        objectModel = 'prop_shower_01',
        isPublic = false
    },
    {
        coords = vector3(-1197.45, -774.68, 17.32), 
        heading = 300.0,
        type = 'shower',
        objectModel = 'prop_shower_01',
        isPublic = true
    },
    {
        coords = vector3(264.80, -1004.80, -100.00), 
        heading = 30.0,
        type = 'sink',
        objectModel = 'prop_sink_01',
        isPublic = false
    },
    {
        coords = vector3(431.29, -807.33, 29.49), 
        heading = 0.0,
        type = 'sink', 
        objectModel = 'prop_sink_02',
        isPublic = true
    }
}

-- [[ CONFIGURACIÓN DE COOLDOWNS ]] -----------------------------------
Config.Cooldowns = {
    toilet = 180,
    urinal = 120,
    shower = 300,
    sink = 60
}

print('[ESX_BATHROOM] Configuración verificada y cargada con tunables para higiene/NPCs/PTFX.')
