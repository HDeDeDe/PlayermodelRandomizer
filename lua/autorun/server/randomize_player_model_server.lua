local ConVarExists = ConVarExists
local error = error

--------------------------------------------------------------------------------
local errorDisplayed = false

CreateConVar("sv_playermodel_random_favorite_on_death", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Should playermodel randomization be allowed to occur.")

util.AddNetworkString("model_rand_death_happened")

hook.Add("PostPlayerDeath", "model_rand_death_hookMeBaybee", function (ply)
    if !ConVarExists("sv_playermodel_selector_force") then
        if !errorDisplayed then
            errorDisplayed = true
            error("Enhanced PlayerModel Selector or a variant is not installed. Please install Enhanced PlayerModel Selector or a variant to use this mod.")    
        end
        return
    end

    if !GetConVar("sv_playermodel_random_favorite_on_death"):GetBool() then
        return
    end

    net.Start("model_rand_death_happened")
    net.WritePlayer(ply)
    net.Send(ply)
end )