-----------------------------------------------------------
-- Armored Soldier
-- Model Credits: Magic Nipples (https://steamcommunity.com/workshop/filedetails/?id=1122693988)
-----------------------------------------------------------

local armor_chest = CreateConVar("cmbevo_armored_chest", 1, FCVAR_ARCHIVE, "[Armored Soldier] Durability of chest armor, as a multiplier of max health.", 0)
local armor_limbs = CreateConVar("cmbevo_armored_limbs", 0.666667, FCVAR_ARCHIVE, "[Armored Soldier] Durability of limb armor, as a multiplier of max health.", 0)

NPC.Name = "Armored Soldier"
NPC.Class = "npc_combine_s"
NPC.Model = "models/cmb_evo/armored_soldier_new.mdl"
NPC.Skin = 0
NPC.Weapons = {"weapon_smg1", "weapon_ar2"}
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
    timer.Simple(0, function()
        local max = self:GetMaxHealth()
        local limb = math.Round(max * armor_limbs:GetFloat())
        self.CmbEvoArmor = {
            [HITGROUP_CHEST] = max * armor_chest:GetFloat(),
            [HITGROUP_LEFTARM_ARMOR] = limb,
            [HITGROUP_RIGHTARM_ARMOR] = limb,
            [HITGROUP_LEFTLEG_ARMOR] = limb,
            [HITGROUP_RIGHTLEG_ARMOR] = limb,
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

hook.Add("ScaleNPCDamage", "cmb_evo_armored", function(ent, hitgroup, dmginfo)
    if CMBEVO.GetTag(ent, "armored") == true then
        if hitgroup == HITGROUP_STOMACH then hitgroup = HITGROUP_CHEST end
        local inflictor = dmginfo:GetInflictor()
        if IsValid(inflictor) and inflictor:GetClass() == "player" and IsValid(inflictor:GetActiveWeapon()) then
            inflictor = inflictor:GetActiveWeapon()
        end
        -- https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/sp/src/game/client/hl2mp/c_te_hl2mp_shotgun_shot.cpp#L91
        -- Today in Sorse spaghetti code:
        -- HL2 Shotguns are hard-coded so that half of their pellets are hulls.
        -- This has the unfortunate side-effect of making them ignore hitgroups.
        -- Thanks, Gabe.
        -- We also make the generous assumption that anyone using DMG_BUCKSHOT is also using hull traces
        -- As far as I know only TacRP bothers with this.
        if IsValid(inflictor) and dmginfo:IsDamageType(DMG_BUCKSHOT) then -- inflictor:GetClass() == "weapon_shotgun" then
            -- Hopefully the first pellet connects, otherwise we don't actually know what it could have hit
            if hitgroup == HITGROUP_GENERIC then
                hitgroup = ent.LastHitGroup or HITGROUP_CHEST
            else
                ent.LastHitGroup = hitgroup
            end
        end

        local melee_damage = dmginfo:IsDamageType(DMG_CLUB) or dmginfo:IsDamageType(DMG_SLASH) or dmginfo:GetDamageType() == DMG_GENERIC
        if hitgroup == HITGROUP_GENERIC and melee_damage then
            hitgroup = HITGROUP_CHEST
        end

        -- TacRP weapons hit arms too hard, so they are protected too
        if IsValid(inflictor) and inflictor.ArcticTacRP then
            if hitgroup == HITGROUP_LEFTARM then
                hitgroup = HITGROUP_LEFTARM_ARMOR
            elseif hitgroup == HITGROUP_RIGHTARM then
                hitgroup = HITGROUP_RIGHTARM_ARMOR
            end
        end

        -- Exposed back?
        if hitgroup == HITGROUP_CHEST and not ent.CmbEvoArmorBackplate then
            local _, bang = ent:GetBonePosition(ent:LookupBone("ValveBiped.Bip01_Spine2"))
            if (dmginfo:GetDamageForce():GetNormalized():Dot(bang:Right()) < 0) then
                hitgroup = HITGROUP_GENERIC
            end
        end

        if ent.CmbEvoArmor == nil then
            ent.CmbEvoArmor = {
                [HITGROUP_CHEST] = armor_chest:GetInt(),
                [HITGROUP_LEFTARM_ARMOR] = armor_limbs:GetInt(),
                [HITGROUP_RIGHTARM_ARMOR] = armor_limbs:GetInt(),
                [HITGROUP_LEFTLEG_ARMOR] = armor_limbs:GetInt(),
                [HITGROUP_RIGHTLEG_ARMOR] = armor_limbs:GetInt(),
            }
        end

        if (ent.CmbEvoArmor[hitgroup] or 0) > 0 then

            local dmg = dmginfo:GetDamage()
            local dmg_to_hp
            if IsValid(inflictor) and inflictor.ArcticTacRP then
                dmg_to_hp = dmg * math.Clamp(math.max(inflictor:GetValue("ArmorPenetration") - 0.66667, 0) * 3, 0, 1)
                dmg = (dmg - dmg_to_hp) * inflictor:GetValue("ArmorBonus")
            else
                if dmginfo:IsDamageType(DMG_BUCKSHOT) then
                    dmg = dmg * 0.75
                elseif melee_damage then
                    dmg = dmg * 0.25
                end
                dmg_to_hp = math.max(dmg - ent.CmbEvoArmor[hitgroup], 0)
            end

            -- Block damage and hurt armor
            dmginfo:SetDamage(dmg_to_hp)
            ent.CmbEvoArmor[hitgroup] = ent.CmbEvoArmor[hitgroup] - dmg

            local dir = dmginfo:GetDamageForce():GetNormalized()

            if dmg_to_hp <= 0 then
                -- don't play bleed effects since we weren't hurt
                ent.CmbEvoBlockDamage = true
            end

            local eff = EffectData()
            eff:SetOrigin(dmginfo:GetDamagePosition() - dir)
            eff:SetNormal(-dir)

            if dmg > 0 then
                util.Effect("MetalSpark", eff)
            end

            if ent.CmbEvoArmor[hitgroup] <= 0 then
                -- broken!
                if ent.CmbEvoArmorBodygroup and ent.CmbEvoArmorBodygroup[hitgroup] then
                    ent:SetBodygroup(ent.CmbEvoArmorBodygroup[hitgroup], 1)
                end
                ent:EmitSound("^npc/strider/strider_step" .. math.random(1, 3) .. ".wav", 80, math.Rand(95, 100), 1, CHAN_BODY)
                ent:SetSchedule(SCHED_FLINCH_PHYSICS)
                if hitgroup == HITGROUP_CHEST or ent:Health() <= ent:GetMaxHealth() * 0.5 or math.random() <= 0.25 then
                    if ent:GetClass() == "npc_combine_s" then
                        ent:PlaySentence("COMBINE_COVER", 0, 1)
                        ent:SetKeyValue("TacticalVariant", "0") -- Pussy Mode Activated
                    else
                        -- metropolice
                        ent:PlaySentence("METROPOLICE_COVER_HEAVY_DAMAGE", 0, 1)
                    end
                    timer.Simple(1, function()
                        if IsValid(ent) then
                            ent:SetSchedule(SCHED_TAKE_COVER_FROM_ENEMY)
                        end
                    end)
                elseif ent:GetClass() == "npc_combine_s" then
                    ent:PlaySentence("COMBINE_TAUNT", 0, 1)
                end
                eff:SetRadius(8)
                util.Effect("cball_bounce", eff)
            else
                ent:EmitSound("player/kevlar" .. math.random(1, 5) .. ".wav", 80, math.Rand(95, 100), 1, CHAN_BODY)
            end
        -- elseif limbs[hitgroup] then
            -- Apply sandbox's 25% damage multiplier, since these are not standard hitgroups
            -- dmginfo:ScaleDamage(0.25)
        end
    end
end)