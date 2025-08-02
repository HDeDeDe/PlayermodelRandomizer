local print = function (s)
    return
end
local istable = istable
local GetConVar = GetConVar
local RunConsoleCommand = RunConsoleCommand
local function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

--------------------------------------------------------------------------------
local borked = false
local lastKnownLength = 0
local usedNumbers = {}
local modelsLength = 0
local models = {}

local function ForceUnique( num, targetLength )
    local randomNumber = num
    if GetConVar("cl_playermodel_random_unique"):GetBool() then
        local usedLength = tablelength(usedNumbers)
        if usedLength == targetLength then
            usedNumbers = {}
            usedLength = 0
        end
        for i=1, usedLength do
            if usedLength == 0 then
                break
            end
            if randomNumber == usedNumbers[i] then
                randomNumber = math.random(length)
                i = 1
            end
        end
        usedNumbers[usedLength + 1] = randomNumber
        -- print("Length of list: " .. usedLength + 1)
        -- for k, v in pairs(usedNumbers) do
        --     print(usedNumbers[k])
        -- end
    end
    return randomNumber
end


local function SelectFavorite()
    if !GetConVar("cl_playermodel_random_favorite_on_death"):GetBool() then
        return
    end
    
    local favorites = {}
    
    if file.Exists("lf_playermodel_selector/cl_favorites.txt", "DATA") then
        --print("Found favorites")
        local loaded = util.JSONToTable(file.Read("lf_playermodel_selector/cl_favorites.txt", "DATA"))
        if istable(loaded) then
            --print("Favorites loaded")
            local count = 1
            for k, v in pairs(loaded) do
                favorites[count] = tostring(k)
                --print(favorites[count])
                count = count + 1
            end
            loaded = nil
        end
    end
    
    if istable(favorites) then
        local length = tablelength(favorites)
        if lastKnownLength ~= length then
            lastKnownLength = length
            usedNumbers = {}
        end
        local randomNumber = math.random(length)
        ForceUnique(randomNumber, length)

        RunConsoleCommand("playermodel_loadfav", favorites[randomNumber])
    end
    
    favorites = nil
end

local function CreateClientsideHooks()
    CreateClientConVar( "cl_playermodel_random_on_death", "0", true, false)
    CreateClientConVar( "cl_playermodel_random_favorite", "0", true, false)
    CreateClientConVar( "cl_playermodel_random_unique", "0", true, false)
    
    net.Receive("model_rand_death_happened", function (len, _)
        if borked then
            return
        end
        local localPly = LocalPlayer()
        local ply = net.ReadPlayer()
        if ply:IsValid() and ply:IsPlayer() and ply == localPly then
            SelectFavorite()
        end
    end)
    
    hook.Add("PopulateToolMenu", "RandomizePlayermodelSettings", function ()
        spawnmenu.AddToolMenuOption( "Options", "Randomize Playermodel", "plr_rand_options_server", "#Server", "", "", function ( panel )
            panel:CheckBox("Allow randomization", "sv_playermodel_random_favorite_on_death")
        end)
        spawnmenu.AddToolMenuOption( "Options", "Randomize Playermodel", "plr_rand_options_client", "#Client", "", "", function ( panel )
            panel:CheckBox("Randomize on death", "cl_playermodel_random_on_death")
            panel:CheckBox("Pick from favorites", "cl_playermodel_random_favorite")
            panel:CheckBox("Force unique model", "cl_playermodel_random_unique")
        end)
    end)
end

CreateClientsideHooks()

hook.Add("Initialize", "playermodel_randomizer_check_for_req_client", function ()
    if !ConVarExists("cl_playermodel_selector_force") then
        borked = true
        error("Enhanced PlayerModel Selector or a variant is not installed. Please install Enhanced PlayerModel Selector or a variant to use this mod.")
    end
    borked = false 
end)
