-----------------------------------------------------------
-- Eastern Dispatch
-- Model: https://gamebanana.com/mods/183076
-----------------------------------------------------------

NPC.Name = "Eastern Dispatch"
NPC.Class = "npc_combine_s"
NPC.Model = "models/cmb_evo/eastern_dispatch.mdl"
NPC.Skin = 0
NPC.Weapons = {"cmbevo_smg_ed"}
NPC.SpawnFlags = SF_NPC_LONG_RANGE
NPC.KeyValues = {
    TacticalVariant = "0",
    NumGrenades = "5",
}
NPC.Tags = {["resist_exp"] = true}
NPC.Squad = "overwatch_eastern"

NPC.GrenadeEntity = "cmbevo_nade_ed"

function NPC:OnGrenadeCreated(ent)
    local tgt = self:GetEnemy()

    if not self.CMBEVO_EDCharging and IsValid(tgt) then

        -- Do not charge NPCs that are incapable of ranged attacks (zombies, antlions) cause that's silly
        -- Instead, back off
        local enemy_is_melee = false
        if tgt:IsNPC() then
            local caps = tgt:CapabilitiesGet()
            if bit.band(caps, CAP_WEAPON_RANGE_ATTACK1 + CAP_INNATE_RANGE_ATTACK1) == 0 then
                enemy_is_melee = true
            end
        end

        if enemy_is_melee then
            self:SetIdealActivity(ACT_SIGNAL_HALT)
        else
            self:SetIdealActivity(ACT_SIGNAL_ADVANCE)
        end

        self:PlaySentence("COMBINE_ASSAULT", 0, 1)

        for _, npc in pairs(ai.GetSquadMembers(self:GetSquad())) do
            if npc:GetPos():DistToSqr(self:GetPos()) <= 512 * 512 and IsValid(npc:GetEnemy()) and not npc.CMBEVO_EDCharging then
                npc.CMBEVO_EDCharging = true

                if enemy_is_melee then
                    local tr = util.TraceLine({
                        start = npc:GetPos(),
                        endpos = npc:GetPos() + (npc:GetPos() - tgt:GetPos()):GetNormalized() * 256,
                        mask = MASK_SOLID_BRUSHONLY,
                    })
                    npc:SetSaveValue("m_vecLastPosition", tr.HitPos - tr.Normal * 32)
                    npc:SetSchedule(SCHED_FORCED_GO)
                    timer.Simple(3, function()
                        if IsValid(npc) then
                            npc:SetSchedule(SCHED_ESTABLISH_LINE_OF_FIRE)
                        end
                    end)
                else
                    local dist = tgt:GetPos():Distance(npc:GetPos())
                    local dir = Vector(1, 0, 0):Angle()
                    dir:RotateAroundAxis(Vector(0, 0, 1), math.Rand(0, 360))
                    local tr = util.TraceLine({
                        start = tgt:GetPos() + Vector(0, 0, 8),
                        endpos = tgt:GetPos() + dir:Forward() * math.Rand(48, 96),
                        mask = MASK_SOLID_BRUSHONLY,
                    })
                    npc:SetSaveValue("m_vecLastPosition", tr.HitPos - tr.Normal * 16)
                    npc:SetSchedule(SCHED_FORCED_GO_RUN)
                    timer.Simple(math.Clamp(dist / 200, 1, 3) * math.Rand(0.8, 1.2) + (npc == self and 1 or 0), function()
                        if IsValid(npc) then
                            npc:SetSchedule(SCHED_ESTABLISH_LINE_OF_FIRE)
                        end
                    end)
                end

                local cur_squad = npc:GetSquad() -- each npc gets their own squad so everyone gets to shoot
                local cur_prof = npc:GetCurrentWeaponProficiency()
                npc:SetCurrentWeaponProficiency(math.min(cur_prof + 2, WEAPON_PROFICIENCY_PERFECT))
                npc:SetSquad("eastern_charge_" .. npc:EntIndex())

                local glow = ents.Create("env_sprite")
                glow:SetKeyValue("model", "sprites/glow08.vmt")
                glow:SetKeyValue("scale", "0.2")
                glow:SetKeyValue("rendermode", "5")
                glow:SetKeyValue("renderamt", "200")
                glow:SetKeyValue("rendercolor", "255 175 0")
                glow:SetPos(npc:EyePos())
                glow:SetAttachment(npc, 3) -- deprecate my balls
                glow:Spawn()
                glow:Fire("ShowSprite")

                timer.Simple(5, function()
                    if IsValid(npc) then
                        npc.CMBEVO_EDCharging = nil
                        npc:SetCurrentWeaponProficiency(cur_prof)
                        npc:SetSquad(cur_squad)
                        SafeRemoveEntity(glow)
                    end
                end)
            end
        end
    end
end

function NPC:Think()
    if (self.CMBEVO_NextThink or 0) > CurTime() then return end
    self.CMBEVO_NextThink = CurTime() + 1

    -- Force throw grenade if enemy is at point blank, or if we are only member of squad (desperation)
    if not self.CMBEVO_EDCharging and (self.CMBEVO_NextDangerNade or 0) < CurTime() and IsValid(self:GetEnemy()) and (not self:GetEnemy():IsPlayer() or math.random() <= 0.5) then -- only 50% chance per try for players
        local dist_sqr = self:GetEnemy():GetPos():DistToSqr(self:GetPos())

        if (self:GetSquad() and ai.GetSquadMemberCount(self:GetSquad()) <= 1) or dist_sqr <= 256 * 256 then
            -- ThrowGrenadeAtTarget requires an entity with a targetname.
            -- Generate a helper point entity to point it.
            local tgtname = "cmbevo_throwtgt_" .. self:EntIndex()
            local tgt = ents.Create("info_target")
            tgt:SetPos(self:GetEnemy():WorldSpaceCenter() + VectorRand() * Lerp((dist_sqr - 256 * 256) / 512 * 512, 12, 72))
            tgt:SetKeyValue("targetname", tgtname)
            tgt:Spawn()
            SafeRemoveEntityDelayed(tgt, 1)
            self:Fire("ThrowGrenadeAtTarget", tgtname)
            self.CMBEVO_NextDangerNade = CurTime() + 5

            self:PlaySentence("COMBINE_THROW_GRENADE", 0, 1)
        end
    end
end

hook.Add("EntityTakeDamage", "cmb_evo_resist_exp", function(ent, dmginfo)
    if CMBEVO.GetTag(ent, "resist_exp") == true and dmginfo:IsExplosionDamage() then
        dmginfo:ScaleDamage(0.3)
    end
end)