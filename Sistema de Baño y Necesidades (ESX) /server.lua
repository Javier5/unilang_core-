-- Server-side validation to prevent clients from bypassing shop hygiene checks
RegisterServerEvent('esx_bathroom:server:canInteractWithShop')
AddEventHandler('esx_bathroom:server:canInteractWithShop', function()
    local src = source
    local hig = PlayerData.Hygiene[src] and PlayerData.Hygiene[src].level or 100
    local allowed = hig >= (Config.HygieneSystem.NPCReactThreshold or 20)
    TriggerClientEvent('esx_bathroom:server:canInteractResult', src, allowed)
end)
