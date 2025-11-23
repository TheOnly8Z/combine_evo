-----------------------------------------------------------
-- Recon Soldier
-- Model Credits: TBD
-----------------------------------------------------------

NPC.Name = "Combine Recon"
NPC.Class = "npc_combine_s"
NPC.Model = "models/cmb_evo/armored_soldier_new.mdl"
NPC.Skin = 0
NPC.Weapons = {"cmbevo_dmr"}
NPC.KeyValues = {
    tacticalvariant = "0",
    numgrenades = "0",
}
NPC.SpawnFlags = 256 -- "Long Visibility/Shoot"
NPC.Tags = {["armored"] = true}

local HITGROUP_LEFTARM_ARMOR = 11
local HITGROUP_RIGHTARM_ARMOR = 12
local HITGROUP_LEFTLEG_ARMOR = 13
local HITGROUP_RIGHTLEG_ARMOR = 14

function NPC:OnSpawn(ply)
    -- This is BEFORE sandbox's 25% limb damage multiplier
    -- local armor_chest = GetConVar("cmbevo_armored_chest")
    local armor_limbs = GetConVar("cmbevo_armored_limbs")

    timer.Simple(0, function()
        local max = self:GetMaxHealth()
        local limb = math.Round(max * armor_limbs:GetFloat())
        self.CmbEvoArmor = {
            -- [HITGROUP_CHEST] = max * armor_chest:GetFloat(),
            [HITGROUP_LEFTARM_ARMOR] = limb,
            [HITGROUP_RIGHTARM_ARMOR] = limb,
            -- [HITGROUP_LEFTLEG_ARMOR] = limb,
            -- [HITGROUP_RIGHTLEG_ARMOR] = limb,
        }
    end)

    self.CmbEvoArmorBodygroup = {
        [HITGROUP_CHEST] = 1,
        [HITGROUP_LEFTARM_ARMOR] = 2,
        [HITGROUP_RIGHTARM_ARMOR] = 3,
        [HITGROUP_LEFTLEG_ARMOR] = 4,
        [HITGROUP_RIGHTLEG_ARMOR] = 5,
    }
    self.CmbEvoArmorBackplate = false
end

if CLIENT then return end
