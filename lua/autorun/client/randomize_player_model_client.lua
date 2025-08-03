local printDebug = print
local printRelease = function (s)
    return
end
local print = printRelease
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
local debugging = false 

local function ToggleDebugging()
    if debugging then
        print = printRelease
        debugging = false 
        return 
    end
    print = printDebug
    debugging = true
end

local function GetRandomModel( targetLength )
    local randomNumber = math.random(targetLength)
    if GetConVar("cl_playermodel_random_unique"):GetBool() then
        local usedLength = tablelength(usedNumbers)
        if usedLength == targetLength then
            usedNumbers = {}
            usedLength = 0
        end
        local itterations = 0
        local itterationCvar = GetConVar("cl_playermodel_random_itteration_limit")
        if itterationCvar:GetInt() =< 0 then
            itterationCvar:SetInt(1000)
        end
        local itterationLimit = itterationCvar:GetInt()
        local count = 1

        while count <= usedLength do
            if itterations > itterationLimit then
                if GetConVar("cl_playermodel_random_itteration_alert"):GetBool() then
                    ErrorNoHalt("[Playermodel Randomizer] Exceeded itteration limit, ignoring unique list. \n")
                end
                return randomNumber
            end
            if randomNumber == usedNumbers[count] then
                print("Reroll " .. randomNumber)
                randomNumber = math.random(targetLength)
                count = 1
            end
            count = count + 1
            itterations = itterations + 1
        end
        usedNumbers[usedLength + 1] = randomNumber
        print("Length of list: " .. usedLength + 1)
        for k, v in pairs(usedNumbers) do
            print(usedNumbers[k])
        end
    end
    return randomNumber
end

local function CheckForValidModels()
    local modelsTemp = player_manager.AllValidModels()
    modelsLength = 0
    for k, v in pairs(modelsTemp) do
        modelsLength = modelsLength + 1
        models[modelsLength] = k
    end
end


local function SelectFavorite()
    local favorites = {}
    
    if file.Exists("lf_playermodel_selector/cl_favorites.txt", "DATA") then
        print("Found favorites")
        local loaded = util.JSONToTable(file.Read("lf_playermodel_selector/cl_favorites.txt", "DATA"))
        if istable(loaded) then
            print("Favorites loaded")
            local count = 1
            for k, v in pairs(loaded) do
                favorites[count] = tostring(k)
                print(favorites[count])
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

        local randomNumber = GetRandomModel(length)
        print(favorites[randomNumber])
        RunConsoleCommand("playermodel_loadfav", favorites[randomNumber])
    end
    
    favorites = nil
end

local function SelectRandom(player)
    if !GetConVar("cl_playermodel_random_on_death"):GetBool() then
        return 
    end
    if GetConVar("cl_playermodel_random_favorite"):GetBool() then
        SelectFavorite()
        return 
    end
    
    if !istable(models) or modelsLength == 0 then
        CheckForValidModels()
    end

    if lastKnownLength ~= 0 then
        local lastKnownLength = 0
        local usedNumbers = {}
    end

    local randomNumber = GetRandomModel(modelsLength)
    
    print(models[randomNumber])
    RunConsoleCommand("cl_playermodel", models[randomNumber])
    RunConsoleCommand("playermodel_apply")
end

local function CreateClientsideHooks()
    CreateClientConVar( "cl_playermodel_random_on_death", "0", true, false)
    CreateClientConVar( "cl_playermodel_random_favorite", "0", true, false)
    CreateClientConVar( "cl_playermodel_random_unique", "0", true, false)
    CreateClientConVar( "cl_playermodel_random_itteration_limit", "1000", true, false)
    CreateClientConVar( "cl_playermodel_random_itteration_alert", "1", true, false)
    concommand.Add("cl_playermodel_random_debug_toggle", ToggleDebugging, nil, nil, {FCVAR_CHEAT})
    
    net.Receive("model_rand_death_happened", function (len, _)
        if borked then
            return
        end
        local localPly = LocalPlayer()
        local ply = net.ReadPlayer()
        if ply:IsValid() and ply:IsPlayer() and ply == localPly then
            SelectRandom(ply)
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
    CheckForValidModels()
end)
