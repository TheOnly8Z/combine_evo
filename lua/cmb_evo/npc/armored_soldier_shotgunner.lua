-----------------------------------------------------------
-- Armored Soldier
-- Model Credits: Magic Nipples (https://steamcommunity.com/workshop/filedetails/?id=1122693988)
-----------------------------------------------------------

NPC.Name = "Armored Shotgunner"
NPC.Class = "npc_combine_s"
NPC.Model = "models/cmb_evo/armored_soldier_new.mdl"
NPC.Skin = 1
NPC.Weapons = {"weapon_shotgun"}
NPC.KeyValues = {
    tacticalvariant = "1",
    numgrenades = "5",
}
NPC.Tags = {["armored"] = true}

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
        [HITGROUP_CHEST] = 1,
        [HITGROUP_LEFTARM_ARMOR] = 2,
        [HITGROUP_RIGHTARM_ARMOR] = 3,
        [HITGROUP_LEFTLEG_ARMOR] = 4,
        [HITGROUP_RIGHTLEG_ARMOR] = 5,
    }
end