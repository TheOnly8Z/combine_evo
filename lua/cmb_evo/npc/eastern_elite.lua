-----------------------------------------------------------
-- Eastern Dispatch
-- Model Credits: https://gamebanana.com/mods/183076
-- Weapon Credits: STUDIO RADI-8, ported by Kali (https://steamcommunity.com/sharedfiles/filedetails/?id=146626186)
-----------------------------------------------------------

NPC.Name = "Eastern Elite"
NPC.Class = "npc_combine_s"
NPC.Model = "models/cmb_evo/eastern_elite.mdl"
NPC.Skin = 0
NPC.Weapons = {"cmbevo_eastern_ar"}
NPC.SpawnFlags = 16384 + 262144 -- SF_NPC_NO_PLAYER_PUSHAWAY + SF_COMBINE_NO_AR2DROP
NPC.Health = 70 -- sk_combine_guard_health
NPC.Proficiency = WEAPON_PROFICIENCY_GOOD
NPC.KeyValues = {
    TacticalVariant = "0",
    NumGrenades = "8",
}
NPC.Tags = {["eastern_assault"] = 2, ["resist_exp"] = true, ["armored"] = true, ["melee_explosion"] = {200, 40}}
NPC.Squad = "overwatch_eastern"

NPC.GrenadeEntity = "cmbevo_nade_ed"

local HITGROUP_LEFTARM_ARMOR = 11
local HITGROUP_LEFTLEG_ARMOR = 13
local HITGROUP_RIGHTLEG_ARMOR = 14

function NPC:OnSpawn(ply)
    timer.Simple(0, function()
        local max = self:GetMaxHealth()
        local limb = math.Round(max * GetConVar("cmbevo_armored_limbs"):GetFloat())
        self.CmbEvoArmor = {
            [HITGROUP_LEFTARM_ARMOR] = limb,
            [HITGROUP_LEFTLEG_ARMOR] = limb,
            [HITGROUP_RIGHTLEG_ARMOR] = limb,
        }
    end)
    self.CmbEvoArmorBodygroup = {
        [HITGROUP_LEFTARM_ARMOR] = 1,
        [HITGROUP_LEFTLEG_ARMOR] = 2,
        [HITGROUP_RIGHTLEG_ARMOR] = 3,
    }

    -- Elites will shoot ar2 balls instead of throwing grenades, and drop them on death.
    -- If elites don't have weapon_ar2, it shoots nothing. Not ideal!
    if IsValid(self:GetActiveWeapon()) and self:GetActiveWeapon():GetClass() == "weapon_ar2" then
        self:SetSaveValue("m_fIsElite", "1")
    end

    -- We set the elite status too late so game doesn't use elite's health value.
    self:SetMaxHealth(GetConVar("sk_combine_guard_health"):GetInt())
    self:SetHealth(self:GetMaxHealth())
end


function NPC:OnGrenadeCreated(ent)
    -- CMBEVO.EasternAssault(self)
end

local defaultsquads = {["overwatch"] = true, ["overwatch_eastern"] = true}
local squadclr = {
    Color(255, 75, 75),
    Color(255, 255, 75),
    Color(75, 255, 75),
    Color(75, 255, 255),
    Color(75, 75, 255),
    Color(255, 75, 255),
    Color(255, 150, 75),
    Color(150, 75, 255),
}
local squadi = 1
function NPC:Think()
    -- Split up squads if it gets too big
    local squad = self:GetSquad()
    local squadcount = self:GetSquad() and ai.GetSquadMemberCount(squad)
    if ((defaultsquads[squad] and ai.GetSquadMemberCount("overwatch_eastern") > 2) or (string.Left(squad, 8) == "eastern_" and squadcount < 3 and ai.GetSquadMemberCount("overwatch_eastern") > 0)) and (self.CMBEVO_NextSquadCheck or 0) < CurTime() then
        self.CMBEVO_NextSquadCheck = CurTime() + 5
        local count = 3
        local newsquad = "eastern_" .. squadi
        local clr = squadclr[(squadi % #squadclr) + 1]

        if defaultsquads[squad] then
            self:SetSquad(newsquad)

            local slglow = ents.Create("env_sprite")
            slglow:SetKeyValue("model", "sprites/glow04_noz.vmt")
            slglow:SetKeyValue("scale", "0.1")
            slglow:SetKeyValue("rendermode", "5")
            slglow:SetKeyValue("renderamt", "200")
            slglow:SetKeyValue("rendercolor", tostring(clr.r) .. " " .. tostring(clr.g) .. " " .. tostring(clr.b))
            slglow:SetPos(self:GetPos())
            slglow:SetAttachment(self, 2) -- deprecate my balls
            slglow:Spawn()
            slglow:Fire("ShowSprite")
            self.CMBEVO_EDSquadGlow = slglow

            squadi = squadi + 1
        else
            newsquad = squad
            count = 4 - squadcount
            clr = squadclr[(tonumber(string.Right(squad, 1)) % #squadclr) + 1]
        end

        self:PlaySentence("COMBINE_IDLE", 0, 1)
        self:SetActivity(ACT_SIGNAL_GROUP)

        for _, npc in pairs(ai.GetSquadMembers("overwatch_eastern")) do
            if not CMBEVO.GetTag(npc, "eastern_assault") or npc:GetPos():DistToSqr(self:GetPos()) >= 1024 * 1024 then continue end

            count = count - 1
            npc:SetSquad(newsquad)
            npc:PlaySentence("COMBINE_ANSWER", math.Rand(0, 0.5), 1)

            local glow = ents.Create("env_sprite")
            glow:SetKeyValue("model", "sprites/glow04_noz.vmt")
            glow:SetKeyValue("scale", "0.05")
            glow:SetKeyValue("rendermode", "5")
            glow:SetKeyValue("renderamt", "150")
            glow:SetKeyValue("rendercolor", tostring(clr.r) .. " " .. tostring(clr.g) .. " " .. tostring(clr.b))
            glow:SetPos(npc:GetPos())
            glow:SetAttachment(npc, 2) -- deprecate my balls
            glow:Spawn()
            glow:Fire("ShowSprite")
            npc.CMBEVO_EDSquadGlow = glow

            if not IsValid(npc:GetEnemy()) then
                npc:SetTarget(self)
                npc:SetSchedule(SCHED_TARGET_CHASE)
            end
            if count <= 0 then break end
        end

    end

    if bit.band(self:CapabilitiesGet(), CAP_WEAPON_RANGE_ATTACK2) ~= 0
        and IsValid(self:GetEnemy()) and math.random() <= (self:GetEnemy():IsPlayer() and 0.6 or 0.75)
        and IsValid(self:GetActiveWeapon()) and self:GetActivity() ~= ACT_RELOAD then

        local dist_sqr = self:GetEnemy():GetPos():DistToSqr(self:GetPos())

        if (self.CMBEVO_NextOrder or 0) < CurTime() and (self.CMBEVO_EDNextCharge or 0) < CurTime()
                and IsValid(self:GetEnemy()) and self:Visible(self:GetEnemy())
                and ai.GetSquadMemberCount(self:GetSquad()) > 2 then

            self.CMBEVO_NextOrder = CurTime() + 15

            if dist_sqr <= 728 * 728 and math.random() <= 0.75 then

                self:SetActivity(ACT_SIGNAL_TAKECOVER)
                self:PlaySentence("COMBINE_GO_ALERT", 0, 1)

                for _, npc in pairs(ai.GetSquadMembers(self:GetSquad())) do
                    -- if not npc:Visible(self:GetEnemy()) then continue end
                    self.CMBEVO_NextOrder = CurTime() + 15

                    local tgtname = "cmb_evo_throw_" .. npc:EntIndex()
                    local info_target = ents.Create("info_target")
                    info_target:SetKeyValue("targetname", tgtname)
                    info_target:Spawn()
                    info_target:Activate()
                    info_target:SetPos(self:GetEnemy():WorldSpaceCenter() + VectorRand() * 32)
                    npc:PlaySentence("COMBINE_ANSWER", math.Rand(0.2, 0.3), 1)
                    npc:Fire("ThrowGrenadeAtTarget", tgtname, math.Rand(0.5, 0.6))
                    SafeRemoveEntityDelayed(info_target, 2)

                end
            else
                CMBEVO.EasternAssault(self)
            end
            return
        end

        if self:GetActiveWeapon():GetClass() == "cmbevo_eastern_ar" and (self.CMBEVO_NextAltFire or 0) < CurTime()
                and dist_sqr <= 500 * 500
                and math.random() * self:GetActiveWeapon():GetMaxClip2() < self:GetActiveWeapon():Clip2() then
            self.CMBEVO_NextAltFire = CurTime() + math.Rand(1, 2)
            local state = self:GetNPCState()
            self:SetNPCState(NPC_STATE_SCRIPT)
            self:SetSchedule(SCHED_NPC_FREEZE)
            self:GetActiveWeapon():SetNextPrimaryFire(CurTime() + 1)
            self:GetActiveWeapon():SetNextSecondaryFire(CurTime() + 0.5)
            self:EmitSound("cmb_evo/weapons/tgs12-pump.wav", 80, 100, 1, CHAN_ITEM)
            -- self:RestartGesture(ACT_GESTURE_FLINCH_LEFTARM)

            timer.Simple(0.45, function()
                if IsValid(self) and IsValid(self:GetActiveWeapon()) then
                    self:RestartGesture(ACT_GESTURE_RANGE_ATTACK_SHOTGUN)
                    self:GetActiveWeapon():SecondaryAttack()
                    self:SetNPCState(state)
                    self:SetSchedule(SCHED_COMBAT_FACE)
                end
            end)
        elseif (self.CMBEVO_NextDangerNade or 0) < CurTime()
                and self:GetInternalVariable("NumGrenades") > 0 -- we gotta have one!
                and dist_sqr <= 500 * 500
                and (self:GetActiveWeapon():GetClass() == "weapon_ar2" or self:Health() >= 25 or dist_sqr >= 200 * 200) then
            local tgtname = "cmb_evo_throw_" .. self:EntIndex()
            local info_target = ents.Create("info_target")
            info_target:SetKeyValue("targetname", tgtname)
            info_target:Spawn()
            info_target:Activate()
            info_target:SetPos(self:GetEnemy():WorldSpaceCenter() + VectorRand() * 12)
            self:Fire("ThrowGrenadeAtTarget", tgtname, 0.01)
            SafeRemoveEntityDelayed(info_target, 1)

            self.CMBEVO_NextDangerNade = CurTime() + 5
        end
    end
end

hook.Add("EntityTakeDamage", "cmb_evo_melee_explosion", function(ent, dmginfo)
    local npc = dmginfo:GetAttacker()
    if CMBEVO.GetTag(npc, "melee_explosion") and dmginfo:GetDamageType() == DMG_CLUB and (npc.CMBEVO_NextMeleeBoom or 0) < CurTime() then
        local info = CMBEVO.GetTag(npc, "melee_explosion")
        npc.CMBEVO_NextMeleeBoom = CurTime() + 5
        local pos = ent:WorldSpaceCenter()
        timer.Simple(0.05, function()
            local dmg = DamageInfo()
            dmg:SetDamage(info[2])
            dmg:SetDamageType(DMG_BLAST_SURFACE)
            dmg:SetAttacker(npc)
            dmg:SetInflictor(npc)
            util.BlastDamageInfo(dmg, pos, info[1])

            local fx = EffectData()
            fx:SetOrigin(pos)
            util.Effect("HelicopterMegaBomb", fx)
            npc:EmitSound("^cmb_evo/weapons/frag_explode-1.wav", 100, 125, 1, CHAN_ITEM)
        end)
    end
    if CMBEVO.GetTag(npc, "melee_explosion") and dmginfo:GetDamageType() == DMG_BLAST_SURFACE and npc == ent then
        return true
    end
end)