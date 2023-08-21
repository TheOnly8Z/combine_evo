-----------------------------------------------------------
-- Eastern Dispatch
-- Model Credits: https://gamebanana.com/mods/183076
-- Weapon Credits: STUDIO RADI-8, ported by Kali (https://steamcommunity.com/sharedfiles/filedetails/?id=146626186)
-----------------------------------------------------------

NPC.Name = "Eastern Dispatch"
NPC.Class = "npc_combine_s"
NPC.Model = "models/cmb_evo/eastern_dispatch.mdl"
NPC.Skin = 0
NPC.Weapons = {"cmbevo_eastern_smg"}
NPC.SpawnFlags = nil
-- NPC.Health = 50 -- sk_combine_s_health
NPC.KeyValues = {
    TacticalVariant = "0",
    NumGrenades = "4",
}
NPC.Tags = {["eastern_assault"] = 1, ["resist_exp"] = true}
NPC.Squad = "overwatch_eastern"
NPC.Proficiency = WEAPON_PROFICIENCY_GOOD

NPC.GrenadeEntity = "cmbevo_nade_ed"

function CMBEVO.EasternAssault(npc)
    if npc.CMBEVO_EDCharging or (npc.CMBEVO_EDNextCharge or 0) > CurTime() or not CMBEVO.GetTag(npc, "eastern_assault") then return end
    local tgt = npc:GetEnemy()

    -- normal assault behavior: force run to point near enemy
    -- suppressive fire behavior: force walk backwards
    local suppressive_fire = false

    -- enable smart behavior if any elite is in squad
    local smart = false

    -- Do not charge NPCs that are incapable of ranged attacks (zombies, antlions) cause that's silly
    if tgt:IsNPC() then
        local caps = tgt:CapabilitiesGet()
        if bit.band(caps, CAP_WEAPON_RANGE_ATTACK1 + CAP_INNATE_RANGE_ATTACK1) == 0 then
            suppressive_fire = true
        end
    end

    -- Consolidate assault members. Only count nearby squadmates
    local members = {}
    local member_health = 0
    for _, ent in pairs(ai.GetSquadMembers(npc:GetSquad())) do
        if ent == npc or (CMBEVO.GetTag(ent, "eastern_assault") and (ent:GetEnemy() == tgt or ent:GetPos():DistToSqr(npc:GetPos()) <= 728 * 728) and IsValid(npc:GetEnemy()) and not npc.CMBEVO_EDCharging) then
            table.insert(members, ent)

            -- sum health, but only count healthy members
            member_health = member_health + (ent:Health() >= 20 and ent:Health() or 0)

            if CMBEVO.GetTag(ent, "eastern_assault") == 2 then smart = true end
        end
    end

    -- "Smart" assault checks the following:
    -- assault member count is more than enemies near target (players count as 2)
    -- assault member health is more than enemy health sum (only count members with >20 health)
    -- If both conditions meet, assault as normal
    -- If conditons fail, instead do supressive fire
    if not suppressive_fire and smart then
        local enemy_count = 0
        local enemy_health = 0
        for _, ent in pairs(ents.FindInSphere(tgt:GetPos(), 512)) do
            if ent:IsNPC() and ent:GetNPCState() == NPC_STATE_COMBAT and npc:Disposition(ent) == D_HT then
                enemy_count = enemy_count + 1
                enemy_health = enemy_health + ent:Health()
            elseif ent:IsPlayer() and ent:Alive() and npc:Disposition(ent) == D_HT then
                enemy_count = enemy_count + 2
                enemy_health = enemy_health + ent:Health()
            end
        end

        if #members <= enemy_count or member_health < enemy_health then
            suppressive_fire = true
        end
    end

    if suppressive_fire then
        npc:SetActivity(ACT_SIGNAL_GROUP)
    else
        npc:SetActivity(ACT_SIGNAL_ADVANCE)
    end

    for i, ent in ipairs(members) do
        ent.CMBEVO_EDCharging = true
        ent.CMBEVO_EDNextCharge = CurTime() + (tgt:IsPlayer() and 15 or 8)

        if suppressive_fire then
            ent:PlaySentence("COMBINE_ANNOUNCE", 0, math.Rand(0, 3))

            local tr = util.TraceLine({
                start = ent:GetPos(),
                endpos = ent:GetPos() + (ent:GetPos() - tgt:GetPos()):GetNormalized() * 256,
                mask = MASK_SOLID_BRUSHONLY,
            })
            ent:SetSaveValue("m_vecLastPosition", tr.HitPos - tr.Normal * 32)
            ent:SetSchedule(SCHED_FORCED_GO)
            timer.Simple(3, function()
                if IsValid(ent) then
                    ent:SetSchedule(SCHED_ESTABLISH_LINE_OF_FIRE)
                end
            end)
        else
            ent:PlaySentence("COMBINE_FLANK", 0, math.Rand(0.25, 2))

            local dist = tgt:GetPos():Distance(ent:GetPos())
            local dir = Vector(1, 0, 0):Angle()
            dir:RotateAroundAxis(Vector(0, 0, 1), math.Rand(0, 360))
            local tr = util.TraceLine({
                start = tgt:GetPos() + Vector(0, 0, 8),
                endpos = tgt:GetPos() + dir:Forward() * math.Rand(48, 96),
                mask = MASK_SOLID_BRUSHONLY,
            })
            ent:SetSaveValue("m_vecLastPosition", tr.HitPos - tr.Normal * 16)
            ent:SetSchedule(SCHED_FORCED_GO_RUN)
            timer.Simple(math.Clamp(dist / 200, 1, 3) * math.Rand(0.8, 1.2) + (ent == npc and 1 or 0), function()
                if IsValid(ent) then
                    ent:SetSchedule(SCHED_ESTABLISH_LINE_OF_FIRE)
                end
            end)
        end

        local cur_squad = ent:GetSquad() -- each ent gets their own squad so everyone gets to shoot
        local cur_prof = ent:GetCurrentWeaponProficiency()
        ent:SetCurrentWeaponProficiency(math.min(cur_prof + 1, WEAPON_PROFICIENCY_PERFECT))
        ent:SetSquad("cmbevo_assault_" .. ent:EntIndex())

        -- cheat a little and reload their clip so they can shoot during the charge
        ent:GetActiveWeapon():SetClip1(ent:GetActiveWeapon():GetMaxClip1())

        local glow = ents.Create("env_sprite")
        glow:SetKeyValue("model", "sprites/glow08.vmt")
        glow:SetKeyValue("scale", "0.2")
        glow:SetKeyValue("rendermode", "5")
        glow:SetKeyValue("renderamt", "150")

        if CMBEVO.GetTag(ent, "eastern_assault") == 2 then
            glow:SetKeyValue("rendercolor", "255 50 0")
        elseif CMBEVO.GetTag(ent, "eastern_assault") == 1 then
            glow:SetKeyValue("rendercolor", "255 175 0")
        end
        glow:SetPos(ent:EyePos())
        glow:SetAttachment(ent, 3) -- deprecate my balls
        glow:Spawn()
        glow:Fire("ShowSprite")

        ent.CMBEVO_EDGlow = glow

        timer.Simple(5, function()
            if IsValid(ent) then
                ent.CMBEVO_EDCharging = nil
                ent:SetCurrentWeaponProficiency(cur_prof)
                ent:SetSquad(cur_squad)
                SafeRemoveEntity(glow)
            end
        end)
    end
end

function NPC:OnGrenadeCreated(ent)
    CMBEVO.EasternAssault(self)
end

function NPC:Think()
    -- Force throw grenade if enemy is at point blank, or if we are only member of squad (desperation)
    if (self.CMBEVO_NextDangerNade or 0) < CurTime()
            and self:GetInternalVariable("NumGrenades") > 0 -- we gotta have one!
            and IsValid(self:GetEnemy()) and (not self:GetEnemy():IsPlayer() or math.random() <= 0.5) then -- only 50% chance per try for players
        local dist_sqr = self:GetEnemy():GetPos():DistToSqr(self:GetPos())

        if (dist_sqr <= 500 * 500 and (self:GetSquad() and ai.GetSquadMemberCount(self:GetSquad()) <= 1)) or (dist_sqr <= 300 * 300 and self:Health() >= 20) then
            -- ThrowGrenadeAtTarget requires an entity with a targetname.
            -- Generate a helper point entity to point it.
            local tgtname = "cmbevo_throwtgt_" .. self:EntIndex()
            local tgt = ents.Create("info_target")
            tgt:SetPos(self:GetEnemy():WorldSpaceCenter() + VectorRand() * 16)
            tgt:SetKeyValue("targetname", tgtname)
            tgt:Spawn()
            SafeRemoveEntityDelayed(tgt, 1)
            self:Fire("ThrowGrenadeAtTarget", tgtname)
            self.CMBEVO_NextDangerNade = CurTime() + 5
        end
    end
end

hook.Add("EntityTakeDamage", "cmb_evo_resist_exp", function(ent, dmginfo)
    if CMBEVO.GetTag(ent, "resist_exp") == true and dmginfo:IsExplosionDamage() then
        dmginfo:ScaleDamage(0.4)
    end
end)

hook.Add("OnNPCKilled", "cmb_evo_glowcleanup", function(npc, attacker, inflictor)
    if IsValid(npc.CMBEVO_EDGlow) then
        SafeRemoveEntity(npc.CMBEVO_EDGlow)
    end
    if IsValid(npc.CMBEVO_EDSquadGlow) then
        SafeRemoveEntity(npc.CMBEVO_EDSquadGlow)
    end
end)