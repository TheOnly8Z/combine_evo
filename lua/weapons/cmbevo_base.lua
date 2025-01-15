AddCSLuaFile()

SWEP.PrintName = "CMBEVO Base"
SWEP.Spawnable = false

SWEP.WorldModel = "models/weapons/w_pist_usp.mdl"
SWEP.HoldType = "pistol"

SWEP.Primary.ShootSound = "weapon_shotgun.single"
SWEP.Secondary.ShootSound = "weapon_shotgun.single"

SWEP.Primary.Damage = 5
SWEP.Primary.Num = 1
SWEP.Primary.Cone = 0.03
SWEP.Primary.Delay = 0.1

SWEP.Primary.Projectile = nil -- entity class
SWEP.Primary.ProjectileVelocity = 1000
SWEP.Primary.ProjectileVelocityOverDistance = 0.03
SWEP.Primary.ProjectileArc = nil

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

SWEP.Secondary.Damage = 5
SWEP.Secondary.Num = 8
SWEP.Secondary.Cone = 0.04
SWEP.Secondary.Delay = 3
SWEP.Secondary.Tracer = 3
SWEP.Secondary.TracerName = "Tracer"

SWEP.Secondary.Automatic = false
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
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

local function anglerotate(main, off)
    local forward, up, right = main:Forward(), main:Up(), main:Right()

    main:RotateAroundAxis(right, off.p)
    main:RotateAroundAxis(up, off.y)
    main:RotateAroundAxis(forward, off.r)

    return main
end

function SWEP:PrimaryAttack()

    if not self:CanPrimaryAttack() or self:GetNextPrimaryFire() > CurTime() then return end
    self:EmitSound(self.Primary.ShootSound)

    local owner = self:GetOwner()

    if self.Primary.Projectile then
        local ang = owner:GetAimVector():Angle()
        local a = math.Rand(0, 360)
        local angleRand = Angle(math.sin(a), math.cos(a), 0)
        angleRand:Mul(self.Primary.Cone * math.Rand(0, 45) * 1.4142135623730)
        ang = anglerotate(ang, angleRand)

        local vel = self.Primary.ProjectileVelocity + self.Primary.ProjectileVelocityOverDistance * (owner:GetEnemy():GetPos() - owner:GetShootPos()):Length2D()
        if self.Primary.ProjectileArc then
            ang.p = math.max(-89, ang.p - self.Primary.ProjectileArc)
        end

        local bullet = ents.Create(self.Primary.Projectile)
        bullet:SetPos(owner:GetShootPos())
        bullet:SetAngles(ang)
        bullet:SetOwner(owner)
        bullet:Spawn()
        bullet:GetPhysicsObject():SetVelocity(ang:Forward() * vel)
        self:OnProjectileCreated(bullet)
    else
        local bullet = {}
        bullet.Num		= self.Primary.Num
        bullet.Src		= owner:GetShootPos()
        bullet.Dir		= owner:GetAimVector()
        bullet.Spread	= Vector( self.Primary.Cone, self.Primary.Cone, 0 )		-- Aim Cone
        bullet.Tracer	= self.Primary.Tracer
        bullet.TracerName = self.Primary.TracerName
        bullet.Force	= 1
        bullet.HullSize = self.Primary.HullSize
        bullet.Damage	= self.Primary.Damage
        bullet.AmmoType = self.Primary.Ammo
        owner:FireBullets(bullet)
    end

    self:TakePrimaryAmmo(1)
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    if self.Primary.Delay < 0.1 then
        self:GetOwner():NextThink(CurTime() + self.Primary.Delay)
    end

    -- self:GetOwner():MuzzleFlash()

    -- TODO Muzzle Effect

    if IsFirstTimePredicted() and self.Primary.EjectName then
        local att = self:GetAttachment(2)
        if att then
            local eff = EffectData()
            eff:SetEntity(self)
            eff:SetOrigin(att.Pos)
            eff:SetAngles(att.Ang)
            util.Effect(self.Primary.EjectName, eff)
        end
    end
end

function SWEP:SecondaryAttack()

    if not self:CanSecondaryAttack() then return end
    self:EmitSound(self.Secondary.ShootSound)

    local owner = self:GetOwner()

    local bullet = {}
    bullet.Num		= self.Secondary.Num
    bullet.Src		= owner:GetShootPos()
    bullet.Dir		= owner:GetAimVector()
    bullet.Spread	= Vector( self.Secondary.Cone, self.Secondary.Cone, 0 )		-- Aim Cone
    bullet.Tracer	= self.Secondary.Tracer
    bullet.TracerName = self.Secondary.TracerName
    bullet.Force	= 1
    bullet.HullSize = self.Secondary.HullSize
    bullet.Damage	= self.Secondary.Damage
    bullet.AmmoType = self.Secondary.Ammo
    owner:FireBullets(bullet)

    self:TakeSecondaryAmmo(1)
    self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
    if self.Secondary.Delay < 0.1 then
        self:GetOwner():NextThink(CurTime() + self.Secondary.Delay)
    end

    if IsFirstTimePredicted() and self.Secondary.EjectName then
        local att = self:GetAttachment(2)
        if att then
            local eff = EffectData()
            eff:SetEntity(self)
            eff:SetOrigin(att.Pos)
            eff:SetAngles(att.Ang)
            util.Effect(self.Secondary.EjectName, eff)
        end
    end
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

function SWEP:OnProjectileCreated(ent)
end