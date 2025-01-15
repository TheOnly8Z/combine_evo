-----------------------------------------------------------
-- Armored Soldier
-- Model Credits: Magic Nipples (https://steamcommunity.com/workshop/filedetails/?id=1122693988)
-----------------------------------------------------------

local armor_chest = CreateConVar("cmbevo_armored_chest", 40, FCVAR_ARCHIVE, "[Armored Soldier] Durability of chest armor.", 1)
local armor_limbs = CreateConVar("cmbevo_armored_limbs", 25, FCVAR_ARCHIVE, "[Armored Soldier] Durability of limb armor.", 1)

NPC.Name = "Armored Soldier"
NPC.Class = "npc_combine_s"
NPC.Model = "models/cmb_evo/armored_soldier.mdl"
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
    self.CmbEvoArmor = {
        [HITGROUP_CHEST] = armor_chest:GetInt(),
        [HITGROUP_LEFTARM_ARMOR] = armor_limbs:GetInt(),
        [HITGROUP_RIGHTARM_ARMOR] = armor_limbs:GetInt(),
        [HITGROUP_LEFTLEG_ARMOR] = armor_limbs:GetInt(),
        [HITGROUP_RIGHTLEG_ARMOR] = armor_limbs:GetInt(),
    }
end

if CLIENT then return end

local hitgroup_to_bodygroup = {
    [HITGROUP_CHEST] = 1,
    [HITGROUP_LEFTARM_ARMOR] = 2,
    [HITGROUP_RIGHTARM_ARMOR] = 3,
    [HITGROUP_LEFTLEG_ARMOR] = 4,
    [HITGROUP_RIGHTLEG_ARMOR] = 5,
}
local limbs = {
    [HITGROUP_LEFTARM_ARMOR] = true,
    [HITGROUP_RIGHTARM_ARMOR] = true,
    [HITGROUP_LEFTLEG_ARMOR] = true,
    [HITGROUP_RIGHTLEG_ARMOR] = true,
}

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
            if IsValid(inflictor) and inflictor.ArcticTacRP then
                dmg = dmg * inflictor:GetValue("ArmorPenetration")
            elseif dmginfo:IsDamageType(DMG_BUCKSHOT) then
                dmg = dmg * 0.75
            end
            if melee_damage then dmg = dmg * 0.25 end

            -- Block damage and hurt armor
            ent.CmbEvoArmor[hitgroup] = ent.CmbEvoArmor[hitgroup] - dmg
            dmginfo:SetDamage(0)

            local dir = dmginfo:GetDamageForce():GetNormalized()
            local eff = EffectData()
            eff:SetOrigin(dmginfo:GetDamagePosition() - dir)
            eff:SetNormal(-dir)
            util.Effect("MetalSpark", eff)


            if ent.CmbEvoArmor[hitgroup] <= 0 then
                -- broken!
                ent:SetBodygroup(hitgroup_to_bodygroup[hitgroup], 1)
                ent:EmitSound("^npc/strider/strider_step" .. math.random(1, 3) .. ".wav", 80, math.Rand(95, 100), 1, CHAN_BODY)
                ent:SetSchedule(SCHED_FLINCH_PHYSICS)
                if hitgroup == HITGROUP_CHEST or ent:Health() <= ent:GetMaxHealth() * 0.5 or math.random() <= 0.25 then
                    ent:PlaySentence("COMBINE_COVER", 0, 1)
                    ent:SetKeyValue("TacticalVariant", "0") -- Pussy Mode Activated
                    timer.Simple(1, function()
                        if IsValid(ent) then
                            ent:SetSchedule(SCHED_TAKE_COVER_FROM_ENEMY)
                        end
                    end)
                else
                    ent:PlaySentence("COMBINE_TAUNT", 0, 1)
                end
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