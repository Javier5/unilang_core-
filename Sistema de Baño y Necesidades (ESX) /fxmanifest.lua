
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

-- [[ INFORMACIÓN DEL RECURSO ]] -------------------------------------
author 'Tu Nombre'
version '2.0.0'
repository 'https://github.com/tu_usuario/esx_bathroom_system' -- Opcional

-- [[ METADATOS DEL SCRIPT ]] ----------------------------------------
description [[
Sistema avanzado de higiene y necesidades fisiológicas para ESX Legacy.

🚽 SISTEMA DE NECESIDADES FISIOLÓGICAS
• Vejiga e intestinos realistas con persistencia en metadata.
• Efectos de estrés y penalizaciones por necesidades urgentes.
• Alertas inmersivas y consecuencias físicas por retención.

🛁 SISTEMA DE HIGIENE AVANZADO
• Decaimiento natural y progresivo de la limpieza corporal.
• Efectos en la salud y animaciones de incomodidad.

💊 SISTEMA DE ENFERMEDADES INDUCIDAS
• Infecciones y diarrea contraídas por mala higiene prolongada.
• Tratamientos de prevención mediante el uso del baño y duchas.

🎯 CARACTERÍSTICAS TÉCNICAS
• 0.00ms en idle (Altamente optimizado).
• Guardado persistente mediante la metadata nativa de ESX.
]]

-- [[ DEPENDENCIAS ]] ------------------------------------------------
dependencies {
    'es_extended'
}

-- [[ CONFIGURACIÓN COMPARTIDA ]] ------------------------------------
shared_script 'config.lua'

-- [[ ARCHIVOS DEL CLIENTE ]] ----------------------------------------
client_script 'client.lua'

-- [[ ARCHIVOS DEL SERVIDOR ]] ---------------------------------------
server_script 'server.lua'

-- [[ ARCHIVOS DE INTERFAZ / UI ]] ----------------------------------
-- Descomentar estas líneas cuando decidas implementar la interfaz UI
-- ui_page 'html/ui.html'
-- files {
--     'html/**/*'
-- }
 -- [[ REGISTRO DE ÍTEMS USABLES ]] ----------------------------------
ESX.RegisterUsableItem('antidiarreico', function(source)
    TriggerClientEvent('esx_bathroom:useAntidiarrheal', source)
    -- Aquí deberías restar el ítem: xPlayer.removeInventoryItem('antidiarreico', 1)
end)

ESX.RegisterUsableItem('toallitas_humedas', function(source)
    TriggerClientEvent('esx_bathroom:useWetWipes', source)
    -- Aquí deberías restar el ítem: xPlayer.removeInventoryItem('toallitas_humedas', 1)
end)

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

shared_script 'config.lua'
client_script 'client.lua'
server_script 'server.lua'
