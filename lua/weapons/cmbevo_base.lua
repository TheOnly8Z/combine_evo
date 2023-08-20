AddCSLuaFile()

SWEP.PrintName = "CMBEVO Base"
SWEP.Spawnable = false

SWEP.WorldModel = "models/weapons/w_pist_usp.mdl"
SWEP.HoldType = "pistol"

SWEP.Primary.ShootSound = "weapon_shotgun.single"

SWEP.Primary.Damage = 5
SWEP.Primary.Num = 1
SWEP.Primary.Cone = 0.03
SWEP.Primary.Delay = 0.1

SWEP.Primary.Tracer = 5
SWEP.Primary.TracerName = "Tracer"
SWEP.Primary.EjectName = "ShellEject"

-- first number is minimum value (perfect skill), second number is maximum value (poor skill)
SWEP.SpreadFromProficiency = nil -- {15, 15}
SWEP.BurstSettings = nil -- {1, 1, 1}
SWEP.BurstRestTimes = nil -- {0.3, 0.66}

SWEP.Primary.ClipSize = 8
SWEP.Primary.DefaultClip = 8
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "pistol"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.Ammo = "none"

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

function SWEP:Equip(owner)
    if owner:IsPlayer() then self:Remove() end
end

function SWEP:CanBePickedUpByNPCs()
    return true
end

function SWEP:PrimaryAttack()

    if not self:CanPrimaryAttack() then return end
    self:EmitSound(self.Primary.ShootSound)

    local owner = self:GetOwner()

    local bullet = {}
    bullet.Num		= self.Primary.Num
    bullet.Src		= owner:GetShootPos()
    bullet.Dir		= owner:GetAimVector()
    bullet.Spread	= Vector( self.Primary.Cone, self.Primary.Cone, 0 )		-- Aim Cone
    bullet.Tracer	= self.Primary.Tracer
    bullet.TracerName = self.Primary.TracerName
    bullet.Force	= 1
    bullet.Damage	= self.Primary.Damage
    bullet.AmmoType = self.Primary.Ammo
    owner:FireBullets(bullet)

    self:TakePrimaryAmmo(1)
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    if self.Primary.Delay < 0.1 then
        self:GetOwner():NextThink(CurTime() + self.Primary.Delay)
    end

    self:GetOwner():MuzzleFlash()
    -- self:GetOwner():SetAnimation(ACT_RANGE_ATTACK1)
    -- if IsFirstTimePredicted() and self.Primary.EjectName then
    --     local att = self:GetAttachment(2)
    --     if att then
    --         local eff = EffectData()
    --         eff:SetEntity(self)
    --         eff:SetOrigin(att.Pos)
    --         eff:SetAngles(att.Ang)
    --         util.Effect(self.Primary.EjectName, eff)
    --     end
    -- end
end

function SWEP:GetCapabilities()
    return bit.bor(CAP_WEAPON_RANGE_ATTACK1, CAP_INNATE_RANGE_ATTACK1)
end

function SWEP:GetNPCBulletSpread(prof)
    if self.SpreadFromProficiency then
        return Lerp(prof / 4, self.SpreadFromProficiency[2], self.SpreadFromProficiency[1])
    end
end

function SWEP:GetNPCBurstSettings()
    if self.BurstSettings then
        return self.BurstSettings[1], self.BurstSettings[2], self.BurstSettings[3]
    end
end

function SWEP:GetNPCRestTimes()
    if self.BurstRestTimes then
        return self.BurstRestTimes[1], self.BurstRestTimes[2]
    end
end


