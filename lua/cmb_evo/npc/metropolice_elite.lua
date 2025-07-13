-----------------------------------------------------------
-- Elite Metropolice
-- Model Credits: DPotatoman, FaSale, FreeStylaLT (https://steamcommunity.com/sharedfiles/filedetails/?id=2005659006)
-----------------------------------------------------------

NPC.Name = "Hemopathy Unit"
NPC.Class = "npc_metropolice"
NPC.Model = "models/cmb_evo/police_elite_armored.mdl"
NPC.Skin = 0
NPC.Weapons = {"cmbevo_357"}
NPC.KeyValues = {}
NPC.Health = 60
NPC.Tags = {["armored"] = true}
NPC.SpawnFlags = 33554432 + 8388608 -- "Mid-range attacks (halfway between normal + long-range)", "Prevent manhack toss"
NPC.Proficiency = WEAPON_PROFICIENCY_AVERAGE

local HITGROUP_LEFTARM_ARMOR = 11
local HITGROUP_RIGHTARM_ARMOR = 12
local HITGROUP_LEFTLEG_ARMOR = 13
local HITGROUP_RIGHTLEG_ARMOR = 14

function NPC:OnSpawn(ply)
    -- This is BEFORE sandbox's 25% limb damage multiplier
    local armor_chest = GetConVar("cmbevo_armored_chest")
    local armor_limbs = GetConVar("cmbevo_armored_limbs")
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
        [HITGROUP_CHEST] = 2,
        [HITGROUP_LEFTARM_ARMOR] = 3,
        [HITGROUP_RIGHTARM_ARMOR] = 4,
        [HITGROUP_LEFTLEG_ARMOR] = 5,
        [HITGROUP_RIGHTLEG_ARMOR] = 6,
    }

    self.PrimaryWeapon = self:GetActiveWeapon():GetClass()
    self:Give("weapon_stunstick")
    self:Give("cmbevo_357")

    self.CmbEvoGrenades = 8
    self.CmbEvoNextGrenade = CurTime() + math.Rand(6, 12)
end

local meleedistsqr = 96 * 96
local rangedistsqr = 328 * 328
local nademindistsqr = 256 * 256
local nademaxdistsqr = 1500 * 1500
local mins, maxs = -Vector(4, 4, 4), Vector(4, 4, 4)
function NPC:Think()
    local enemy = self:GetEnemy()
    if not IsValid(enemy) or not IsValid(self:GetActiveWeapon()) then return end
    local wep = self:GetActiveWeapon()

    local distsqr = enemy:GetPos():DistToSqr(self:GetPos())

    if wep:GetClass() == "cmbevo_357" and (self.CmbEvoNextSwap or 0) < CurTime()
            and (wep:GetAimTime() == 0 or wep:GetAimTime() <= CurTime() + wep.Primary.AimTime) and distsqr <= meleedistsqr then
        self.CmbEvoNextSwap = CurTime() + math.Rand(3, 5)
        self:SetSchedule(SCHED_COMBAT_STAND)

        wep:StopAim()

        self:SelectWeapon("weapon_stunstick")
        self:NextThink(CurTime())
        self:RestartGesture(self:LookupSequence("activatebaton"), true, true)
    elseif wep:GetClass() == "weapon_stunstick" and (self.CmbEvoNextSwap or 0) < CurTime() and distsqr >= rangedistsqr then
        self.CmbEvoNextSwap = CurTime() + 3
        self:SetSchedule(SCHED_COMBAT_STAND)
        self:SelectWeapon("cmbevo_357")
        self:GetWeapon("cmbevo_357"):SetNextSecondaryFire(CurTime() + 1)
        self:NextThink(CurTime())
        self:RestartGesture(self:LookupSequence("drawpistol"), true, true)
    end

    if self.CmbEvoGrenades > 0 and IsValid(wep) and wep:GetClass() == "cmbevo_357" and (self.CmbEvoNextGrenade or 0) < CurTime() and distsqr >= nademindistsqr and distsqr <= nademaxdistsqr then
        wep:StopAim()

        -- Attempt to find a throw angle
        local throwvelocity
        if IsValid(self:GetEnemy()) then -- view cone check? dont throw behind us
            if self:Visible(self:GetEnemy()) then
                throwvelocity = CMBEVO.VecCheckThrow(self, self:EyePos(), self:GetEnemy():GetPos(), 650, 1, mins, maxs)
            end
            if not throwvelocity then
                local tr = util.TraceLine({
                    start = self:EyePos(),
                    endpos = self:EyePos() + Vector(0, 0, 64),
                    mask = MASK_SOLID,
                    filter = self
                })
                if tr.Fraction == 1 then
                    throwvelocity = CMBEVO.VecCheckToss(self, self:EyePos(), self:GetEnemy():GetPos(), -1, 1, true, mins, maxs)
                end
            end
        end

        if not throwvelocity then
            self.CmbEvoNextGrenade = CurTime() + math.Rand(1, 4)
        else
            self.CmbEvoNextGrenade = CurTime() + math.Rand(6, 12)
            self:SetNPCState(NPC_STATE_SCRIPT)
            self:NextThink(CurTime())
            local seq = self:LookupSequence("grenadethrow")
            local dur = self:SequenceDuration(seq)
            self:AddGestureSequence(seq, true)

            self.CmbEvoGrenades = self.CmbEvoGrenades - 1

            if IsValid(self:GetActiveWeapon()) then
                self:GetActiveWeapon():SetNextPrimaryFire(CurTime() + dur + 1)
                self:GetActiveWeapon():SetNextSecondaryFire(CurTime() + dur + 1)
                self:GetActiveWeapon():SetAimTime(0)
                self:GetActiveWeapon():SetAimLostTime(0)
            end

            timer.Simple(0.8, function()
                if IsValid(self) then
                    local nade = ents.Create("npc_grenade_frag")
                    -- local hand = self:GetBoneMatrix(self:LookupBone("ValveBiped.Anim_Attachment_RH"))
                    -- local bpos, bang = hand:GetTranslation(), hand:GetAngles()
                    nade:SetOwner(self)
                    nade:SetPos(self:EyePos())
                    nade:SetAngles(AngleRand())
                    nade:Spawn()
                    nade:GetPhysicsObject():SetVelocityInstantaneous(throwvelocity)
                    nade:GetPhysicsObject():SetAngleVelocityInstantaneous(VectorRand() * 1000)
                    print(throwvelocity)
                    nade:Fire("SetTimer", 3)

                end
            end)
            timer.Simple(dur + 1, function()
                if IsValid(self) then
                    self:SetNPCState(NPC_STATE_COMBAT)
                end
            end)
        end
    end
end