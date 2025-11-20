-----------------------------------------------------------
-- Combine Suppressor
-- Model Credits: EJ_5527 (https://steamcommunity.com/sharedfiles/filedetails/?id=3351644075)
-----------------------------------------------------------
NPC.Base = "armored_soldier"

NPC.Name = "Suppressor"
NPC.Class = "npc_combine_s"
NPC.Model = "models/cmb_evo/combine_suppressor.mdl"
NPC.Skin = 0
NPC.Weapons = {"cmbevo_suppressor"}
NPC.Proficiency = WEAPON_PROFICIENCY_VERY_GOOD
NPC.Health = 100
NPC.KeyValues = {
    tacticalvariant = "0",
    numgrenades = "0",
}

function NPC:OnSpawn(ply)
    -- This is BEFORE sandbox's 25% limb damage multiplier
    timer.Simple(0, function()
        local max = self:GetMaxHealth()
        local limb = math.Round(max * GetConVar("cmbevo_armored_limbs"):GetFloat())
        self.CmbEvoArmor = {
            [HITGROUP_CHEST] = max * GetConVar("cmbevo_armored_chest"):GetFloat(),
            [HITGROUP_LEFTARM] = limb,
            [HITGROUP_RIGHTARM] = limb,
            [HITGROUP_LEFTLEG] = limb,
            [HITGROUP_RIGHTLEG] = limb,
        }
    end)
    self.CmbEvoArmorBackplate = true
    self:CapabilitiesRemove(CAP_MOVE_SHOOT)
end

function NPC:Think()
    -- local enemy = self:GetEnemy()
    -- local wep = self:GetActiveWeapon()
    -- if IsValid(enemy) and IsValid(wep) and wep:GetClass() == "cmbevo_suppressor" and wep:Clip1() > 0 and self:GetPos():DistToSqr(enemy:GetPos()) <= 2000 * 2000 then
    --     if self.CmbEvoForcedAttack then

    --     elseif self:Visible(enemy) and not self.CmbEvoForcedAttack and wep:GetNextPrimaryFire() <= CurTime() then
    --         self.CmbEvoForcedAttack = true
    --         self:GetActiveWeapon():StartAim(true)
    --         self:SetSchedule(SCHED_FAIL)
    --         self:CapabilitiesRemove(CAP_MOVE_GROUND)

    --         print("start forced attack")
    --     end
    -- elseif self.CmbEvoForcedAttack then
    --     self.CmbEvoForcedAttack = false
    --     -- self:Fire("StopScripting")
    --     -- self:SetNPCState(NPC_STATE_COMBAT)
    --     self:GetActiveWeapon():StopAim()
    --     self:CapabilitiesAdd(CAP_MOVE_GROUND)
    --     print("end forced attack")
    -- end
end