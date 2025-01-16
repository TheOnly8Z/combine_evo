-----------------------------------------------------------
-- Armored Elite Metropolice
-- Model Credits: DPotatoman, FaSale, FreeStylaLT (https://steamcommunity.com/sharedfiles/filedetails/?id=2005659006)
-----------------------------------------------------------

NPC.Name = "Elite Metro-Police"
NPC.Class = "npc_metropolice"
NPC.Model = "models/cmb_evo/police_elite_armored.mdl"
NPC.Skin = 0
NPC.Weapons = {"weapon_357"}
NPC.KeyValues = {
}
NPC.Tags = {["armored"] = true}
NPC.Proficiency = WEAPON_PROFICIENCY_AVERAGE

local HITGROUP_LEFTARM_ARMOR = 11
local HITGROUP_RIGHTARM_ARMOR = 12
local HITGROUP_LEFTLEG_ARMOR = 13
local HITGROUP_RIGHTLEG_ARMOR = 14

function NPC:OnSpawn(ply)
    -- This is BEFORE sandbox's 25% limb damage multiplier
    local armor_chest = GetConVar("cmbevo_armored_chest")
    local armor_limbs = GetConVar("cmbevo_armored_limbs")

    self.CmbEvoArmor = {
        [HITGROUP_CHEST] = armor_chest:GetInt(),
        [HITGROUP_LEFTARM_ARMOR] = armor_limbs:GetInt(),
        [HITGROUP_RIGHTARM_ARMOR] = armor_limbs:GetInt(),
        [HITGROUP_LEFTLEG_ARMOR] = armor_limbs:GetInt(),
        [HITGROUP_RIGHTLEG_ARMOR] = armor_limbs:GetInt(),
    }
    self.CmbEvoArmorBodygroup = {
        [HITGROUP_CHEST] = 2,
        [HITGROUP_LEFTARM_ARMOR] = 3,
        [HITGROUP_RIGHTARM_ARMOR] = 4,
        [HITGROUP_LEFTLEG_ARMOR] = 5,
        [HITGROUP_RIGHTLEG_ARMOR] = 6,
    }
end