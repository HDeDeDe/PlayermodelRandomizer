local GetConVar = GetConVar

--------------------------------------------------------------------------------
local borked = false

local function AddServersideHooks()
    CreateConVar("sv_playermodel_random_favorite_on_death", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Should playermodel randomization be allowed to occur.")

    util.AddNetworkString("model_rand_death_happened")

    hook.Add("PostPlayerDeath", "model_rand_death_hookMeBaybee", function (ply)
        if borked then
            return 
        end
        if !GetConVar("sv_playermodel_random_favorite_on_death"):GetBool() then
            return
        end

        net.Start("model_rand_death_happened")
        net.WritePlayer(ply)
        net.Send(ply)
    end )
end

AddServersideHooks()

hook.Add("Initialize", "playermodel_randomizer_check_for_req_server", function ()
    if !ConVarExists("sv_playermodel_selector_force") then
        borked = true
        error("Enhanced PlayerModel Selector or a variant is not installed. Please install Enhanced PlayerModel Selector or a variant to use this mod.")
    end
    borked = false 
end)
