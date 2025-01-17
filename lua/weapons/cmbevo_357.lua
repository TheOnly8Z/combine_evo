AddCSLuaFile()

SWEP.Base = "cmbevo_base"

SWEP.PrintName = "Elite .357"

SWEP.WorldModel = "models/weapons/tacint/w_mr96.mdl"
SWEP.HoldType = "pistol"

SWEP.Primary.ShootSound = "CMB_EVO.357.Fire"

SWEP.Primary.Damage = 20
SWEP.Primary.Num = 1
SWEP.Primary.Cone = 0.01
SWEP.Primary.Delay = 0.9
SWEP.Primary.Tracer = 1
SWEP.Primary.TracerName = "AR2Tracer"
SWEP.Primary.EjectName = false

SWEP.Primary.AimTime = 1.4
SWEP.Primary.AimTimeThreshold = 1
SWEP.Primary.AimBlindFireChance = 0.5

SWEP.Primary.AimLaserStrength = 10
SWEP.Primary.AimLaserColor = Color(255, 0, 0)

SWEP.SpreadFromProficiency = {0, 3}
SWEP.BurstSettings = {1, 1, 0}
SWEP.BurstRestTimes = {0, 0}

SWEP.Primary.ClipSize = 6
SWEP.Primary.DefaultClip = 6
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "357"


sound.Add({
    name = "CMB_EVO.357.Fire",
    channel = CHAN_WEAPON,
    volume = 1.0,
    level = 100,
    pitch = 90,
    sound = "^cmb_evo/weapons/mr96_fire-1.wav"
})