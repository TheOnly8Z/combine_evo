-----------------------------------------------------------
-- Grenadier
-----------------------------------------------------------

local armor = CreateConVar("cmbevo_mechcrab_armor", 2, FCVAR_ARCHIVE, "[Mechcrab] Durability of mechcrab armor, as a multiplier of its health.", 0)

NPC.Name = "Mechcrab"
NPC.Class = "npc_headcrab" -- npc_cmbevo_mechcrab
NPC.Model = "models/cmb_evo/combinecrab.mdl"
NPC.Skin = 0
NPC.SpawnFlags = 0
NPC.KeyValues = {
}
NPC.Health = 15
NPC.DamageScale = 3
NPC.ForceCombine = true

if CLIENT then return end

function NPC:OnSpawn()
    -- self:SetModelScale(1.3, 0.000001)
    -- self:SetPos(self:GetPos() + Vector(0, 0, 3))
    timer.Simple(0, function()
        self.CmbEvoCrabArmor = self:GetMaxHealth() * armor:GetFloat()
    end)
end

function NPC:OnScaleDamage(hitgroup, dmginfo)

    -- DMG_CLUB instakills headcrabs. this is not desirable to us
    if dmginfo:IsDamageType(DMG_CLUB) then
        dmginfo:SetDamageType(bit.band(dmginfo:GetDamageType(), bit.bnot(DMG_CLUB)))
    end

    if (self.CmbEvoCrabArmor or 0) > 0 then
        local dir = dmginfo:GetDamageForce():GetNormalized()
        if (hitgroup == 11 or hitgroup == 12) then
            local dmg = dmginfo:GetDamage()
            local dmg_to_hp
            if IsValid(inflictor) and inflictor.ArcticTacRP then
                dmg_to_hp = dmg * math.Clamp(math.max(inflictor:GetValue("ArmorPenetration") - 0.5, 0) * 2, 0, 1)
                dmg = (dmg - dmg_to_hp) * inflictor:GetValue("ArmorBonus")
            else
                dmg_to_hp = math.max(dmg - self.CmbEvoCrabArmor, 0)
            end

            dmginfo:SetDamage(dmg_to_hp)
            self.CmbEvoCrabArmor = math.max(0, self.CmbEvoCrabArmor - dmg)

            local eff = EffectData()
            eff:SetOrigin(dmginfo:GetDamagePosition() - dir)
            eff:SetNormal(-dir)
            util.Effect("MetalSpark", eff)
            self:EmitSound("physics/metal/metal_sheet_impact_bullet1.wav", 80, math.Rand(105, 110), 1, CHAN_WEAPON)

            if dmg_to_hp <= 0 then
                self.CmbEvoBlockDamage = true
                return true
            end
        elseif dmginfo:IsDamageType(DMG_CLUB) or dmginfo:IsDamageType(DMG_SLASH) or dmginfo:GetDamageType() == DMG_GENERIC then
            local h_dir = self:WorldSpaceCenter() - dmginfo:GetDamagePosition()
            h_dir.z = 0
            h_dir:Normalize()
            -- local dot = h_dir:Dot(self:GetForward())
            local dmgpos_local = self:WorldToLocal(dmginfo:GetDamagePosition())
            local scale = 1 --1.2
            if ((dmgpos_local.x < 5 * scale and dmgpos_local.x > -10 * scale) or dmgpos_local.z > 20 or math.abs(dmgpos_local.y) > 7 * scale) and not (not self:IsOnGround() and self:GetForward():Dot(dmginfo:GetDamageForce():GetNormalized()) < 0) then -- (dot < 0.6 and dot > -0.5)
                local eff = EffectData()
                eff:SetOrigin(dmginfo:GetDamagePosition() - dir)
                eff:SetNormal(-dir)
                util.Effect("MetalSpark", eff)
                self:EmitSound("physics/metal/metal_sheet_impact_bullet1.wav", 80, math.Rand(105, 110), 1, CHAN_WEAPON)
                self.CmbEvoCrabArmor = math.max(0, self.CmbEvoCrabArmor - dmginfo:GetDamage())
                dmginfo:SetDamage(0)
                self.CmbEvoBlockDamage = true
                return true
            end
        end
    end
end