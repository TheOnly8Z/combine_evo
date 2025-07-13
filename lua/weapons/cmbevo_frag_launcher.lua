AddCSLuaFile()

SWEP.Base = "cmbevo_base"

SWEP.PrintName = "Frag Launcher"

SWEP.WorldModel = "models/weapons/w_rocket_launcher.mdl"
SWEP.HoldType = "shotgun"

SWEP.Primary.ShootSound = "CMB_EVO.FragLauncher.Fire"

SWEP.Primary.Damage = 3
SWEP.Primary.Num = 1
SWEP.Primary.Cone = 0.1
SWEP.Primary.Delay = 0.5
SWEP.Primary.Tracer = 0
SWEP.Primary.TracerName = "Tracer"
SWEP.Primary.EjectName = false

SWEP.Primary.Projectile = "cmbevo_nade_gren"
SWEP.Primary.ProjectileVelocity = 400
SWEP.Primary.ProjectileVelocityOverDistance = 0.5
SWEP.Primary.ProjectileArc = 20
SWEP.Primary.ProjectileSafety = true
SWEP.Primary.ProjectileSafetyDistance = 328

SWEP.SpreadFromProficiency = {15, 24}
SWEP.BurstSettings = {3, 6, 0.3}
SWEP.BurstRestTimes = {0.5, 0.7}

SWEP.Primary.ClipSize = 6
SWEP.Primary.DefaultClip = 6
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "smg1_grenade"

sound.Add({
    name = "CMB_EVO.FragLauncher.Fire",
    channel = CHAN_WEAPON,
    volume = 1.0,
    level = 100,
    pitch = {115, 120},
    sound = "^weapons/ar2/npc_ar2_altfire.wav"
})

DEFINE_BASECLASS(SWEP.Base)

local pussy_distance = 328 * 328
function SWEP:CanPrimaryAttack()
    local enemy = self:GetOwner():GetEnemy()
    if IsValid(enemy) and enemy:GetPos():DistToSqr(self:GetOwner():GetPos()) <= pussy_distance then
        return false
    end
    return BaseClass.CanPrimaryAttack(self)
end

function SWEP:OnProjectileCreated(ent)
    ent:Fire("SetTimer", 3)
    ent:GetPhysicsObject():SetAngleVelocityInstantaneous(VectorRand() * 512)
end