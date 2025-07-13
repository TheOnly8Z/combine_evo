AddCSLuaFile()

SWEP.PrintName = "CMBEVO Base"
SWEP.Spawnable = false

SWEP.WorldModel = "models/weapons/w_pist_usp.mdl"
SWEP.HoldType = "pistol"

SWEP.RenderGroup = RENDERGROUP_BOTH

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

SWEP.Primary.AimTime = 0 -- Must lock onto target for this long before firing
SWEP.Primary.AimTimeThreshold = nil -- If lock on time is longer than this, we won't cancel the shot anymore even if they go behind cover
SWEP.Primary.AimBlindFireChance = 0.5 -- After a shot, this is the chance the NPC will be okay with shooting at cover

SWEP.Primary.AimLaserStrength = 0
SWEP.Primary.AimLaserColor = Color(255, 0, 0)

SWEP.Primary.AimStartSound = "CMB_EVO.ChargeUp"
SWEP.Primary.AimCancelSound = "CMB_EVO.ChargeEnd"

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

SWEP.Primary.Projectile = nil
SWEP.Primary.ProjectileVelocity = nil
SWEP.Primary.ProjectileVelocityOverDistance = nil
SWEP.Primary.ProjectileArc = nil
SWEP.Primary.ProjectileSafety = nil
SWEP.Primary.ProjectileSafetyDistance = nil

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


function SWEP:SetupDataTables()
    self:NetworkVar("Float", 0, "AimTime")
    self:NetworkVar("Float", 1, "AimLostTime")
    self:NetworkVar("Vector", 0, "AimVector")
end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)

    -- NPCs do not think on weapon, so think for them
    if SERVER then
        local t = "cmbevo_think_" .. self:EntIndex()
        timer.Create(t, 0, 0, function()
            if IsValid(self) and IsValid(self:GetOwner()) and self:GetOwner():GetActiveWeapon() == self and self:GetOwner():Health() > 0 then
                self:Think()
            elseif not IsValid(self) then
                timer.Remove(t)
            end
        end)
    end
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
    local owner = self:GetOwner()

    if self.Primary.AimTime > 0 then
        if self:GetNextSecondaryFire() > CurTime() then
            return
        elseif self:GetAimTime() == 0 then
            self:SetAimTime(CurTime())
            self:SetAimLostTime(0)
            self.AllowAimMiss = true

            -- TODO lasers or something
            --self:EmitSound(self.Primary.AimStartSound)
            self.AimSound = CreateSound(self, self.Primary.AimStartSound)
            self.AimSound:PlayEx(1, 85)
            self.AimSound:ChangePitch(150, self.Primary.AimTime)
            return
        elseif CurTime() < self:GetAimTime() + self.Primary.AimTime then
            return
        end
    end

    if self.Primary.Projectile and self.Primary.ProjectileSafety then
        local tr = util.TraceHull({
            start = owner:GetShootPos(),
            endpos = owner:GetShootPos() + owner:GetAimVector() * self.Primary.ProjectileSafetyDistance,
            mask = MASK_SOLID,
            filter = {owner},
            mins = Vector(-1, -1, -1),
            maxs = Vector(1, 1, 1),
        })
        if tr.Fraction < 1 then
            self:SetNextPrimaryFire(CurTime() + 0.25)
            return
        end
    end

    -- self:SetAimTime(0)
    -- self:SetAimLostTime(0)
    if self.AimSound then
        self.AimSound:Stop()
    end
    if self.Primary.AimTime > 0 and math.random() > self.Primary.AimBlindFireChance then
        self.AllowAimMiss = false
    end


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

    self:EmitSound(self.Primary.ShootSound)
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

function SWEP:StopAim()
    self:SetAimTime(0)
    self:SetAimLostTime(0)
    if self.AimSound then
        self.AimSound:Stop()
        self.AimSound = nil
    end
end

function SWEP:Reload()
    BaseClass.Reload(self)
    self:StopAim()
end

function SWEP:Think()
    if IsValid(self:GetOwner()) and self.Primary.AimTime > 0 and self:GetAimTime() > 0 and self:GetNextSecondaryFire() <= CurTime() then
        if (not self.Primary.AimTimeThreshold or CurTime() <= self.GetAimTime() + self.Primary.AimTimeThreshold or (not self.AllowAimMiss or CurTime() >= self:GetAimTime() + self.Primary.AimTime)) and
                (not IsValid(self:GetOwner():GetEnemy()) or not self:GetOwner():Visible(self:GetOwner():GetEnemy())) then
            -- If can't see target for more than this amount of time, they are lost and we cancel the shot
            if self:GetAimLostTime() == 0 then
                self:SetAimLostTime(CurTime() + (self.AllowAimMiss and 0.12 or 0.25))
            elseif self:GetAimLostTime() <= CurTime() then
                self:StopAim()
                if self.AllowAimMiss then
                    self:EmitSound(self.Primary.AimCancelSound)
                end
            end
        else
            if self:GetAimLostTime() == 0 then
                if IsValid(self:GetOwner():GetEnemy()) then
                    self:SetAimVector((self:GetOwner():GetEnemy():EyePos() - self:GetOwner():GetShootPos()):GetNormalized())
                else
                    self:SetAimVector(self:GetOwner():GetAimVector())
                end
            end

            if CurTime() >= self:GetAimTime() + self.Primary.AimTime then
                if self.AllowAimMiss and self:Clip1() > 0 and IsValid(self:GetOwner():GetEnemy()) and self:GetOwner():GetEnemy():Health() > 0 and self:GetOwner():Visible(self:GetOwner():GetEnemy()) then
                    if self:GetNextPrimaryFire() < CurTime() then
                        self:PrimaryAttack()
                    end
                else
                    self:StopAim()
                end
            else
                self:SetAimLostTime(0)
            end
        end
    elseif self.Primary.AimTime > 0 then
        self:StopAim()
    end
end

if CLIENT then
    local lasermat = Material("effects/laser1")
    local flaremat = Material("effects/whiteflare")
    local col2 = Color(200, 200, 200)
    local col = Color(255, 0, 0)

    function SWEP:DrawWorldModel(flag)
        self:DrawModel(flags)
    end

    function SWEP:DrawWorldModelTranslucent(flag)
        local owner = self:GetOwner()
        if IsValid(owner) and self:GetAimTime() > 0 and self.Primary.AimLaserStrength > 0 then
            local att = self:GetAttachment(1)
            local pos = att.Pos
            local tr = util.TraceLine({
                start = pos,
                endpos = pos + (self:GetAimVector() * 5000), -- att.Ang:Forward()
                mask = MASK_SHOT,
                filter = self:GetOwner()
            })

            local strength = Lerp((CurTime() - self:GetAimTime()) / self.Primary.AimTime ^ 4, 0, self.Primary.AimLaserStrength)
            render.SetMaterial(lasermat)
            local width = math.Rand(0.4, 0.5) * strength
            render.DrawBeam(tr.StartPos, tr.HitPos, width * 0.3, 0, 1, col2)
            render.DrawBeam(tr.StartPos, tr.HitPos, width, 0, 1, self.Primary.AimLaserColor)

            if tr.Hit and not tr.HitSky then
                local rad = math.Rand(4, 6) * strength

                render.SetMaterial(flaremat)
                render.DrawSprite(tr.HitPos, rad, rad, self.Primary.AimLaserColor)
                render.DrawSprite(tr.HitPos, rad * 0.3, rad * 0.3, col2)
            end
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

function SWEP:OnRemove()
    if self.AimSound then
        self.AimSound:Stop()
    end
end

function SWEP:OnProjectileCreated(ent) end

sound.Add({
    name = "CMB_EVO.ChargeUp",
    channel = CHAN_WEAPON,
    volume = 0.5,
    level = 80,
    pitch = 100,
    sound = "weapons/physcannon/physcannon_charge.wav"
})

sound.Add({
    name = "CMB_EVO.ChargeEnd",
    channel = CHAN_WEAPON,
    volume = 0.5,
    level = 80,
    pitch = 100,
    sound = "weapons/physcannon/superphys_small_zap3.wav"
})