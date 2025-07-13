-----------------------------------------------------------
-- Grenadier
-----------------------------------------------------------

NPC.Name = "Grenadier"
NPC.Class = "npc_combine_s"
NPC.Model = "models/combine_soldier.mdl"
NPC.Skin = 0
NPC.Weapons = {"cmbevo_frag_launcher"}
NPC.SpawnFlags = 0
NPC.KeyValues = {
    tacticalvariant = "0",
    NumGrenades = "99",
}

NPC.GrenadeEntity = "cmbevo_nade_bounce"

function NPC:OnSpawn(ply)
end

local pussy_distance = 512 * 512
function NPC:Think()
    local enemy = self:GetEnemy()
    if not IsValid(enemy) or not IsValid(self:GetActiveWeapon()) then return end
    local dist_sqr = enemy:GetPos():DistToSqr(self:GetPos())
    if dist_sqr < pussy_distance then

        if (self.CMBEVO_NextDangerNade or 0) < CurTime()
                and self:GetInternalVariable("NumGrenades") > 0 -- we gotta have one!
                and IsValid(self:GetEnemy()) then

            -- ThrowGrenadeAtTarget requires an entity with a targetname.
            -- Generate a helper point entity to point it.
            local tgtname = "cmbevo_throwtgt_" .. self:EntIndex()
            local tgt = ents.Create("info_target")
            tgt:SetPos((self:GetEnemy():GetPos() - self:GetPos()) / 4 + self:GetPos())
            tgt:SetKeyValue("targetname", tgtname)
            tgt:Spawn()
            SafeRemoveEntityDelayed(tgt, 1)
            self:Fire("ThrowGrenadeAtTarget", tgtname)
            self.CMBEVO_NextDangerNade = CurTime() + math.Rand(2, 5)
        elseif self:GetCurrentSchedule() ~= SCHED_TAKE_COVER_FROM_ENEMY then
            self:SetSchedule(SCHED_TAKE_COVER_FROM_ENEMY)
        end
    end
end

if CLIENT then return end
