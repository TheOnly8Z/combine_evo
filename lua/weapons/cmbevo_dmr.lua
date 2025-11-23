AddCSLuaFile()

SWEP.Base = "cmbevo_base"

SWEP.PrintName = "AR2 Marksman"

SWEP.WorldModel = "models/cmb_evo/weapons/w_zr68.mdl"
SWEP.HoldType = "ar2"

SWEP.Primary.ShootSound = "CMB_EVO.AR2DMR.Fire"

SWEP.Primary.Damage = 8
SWEP.Primary.Num = 1
SWEP.Primary.Cone = 0
SWEP.Primary.Delay = 0.1
SWEP.Primary.Tracer = 1
SWEP.Primary.TracerName = "AR2Tracer"
SWEP.Primary.EjectName = false

SWEP.Primary.AimTime = 0.3
SWEP.Primary.AimTimeThreshold = 0.1
SWEP.Primary.AimBlindFireChance = 1
SWEP.Primary.AimBurstLength = {3, 3}
SWEP.Primary.AimCooldown = 0.75

SWEP.Primary.AimStartSound = "CMB_EVO.AR2DMR.ChargeUp"
SWEP.Primary.AimCancelSound = "CMB_EVO.AR2DMR.ChargeEnd"

SWEP.Primary.AimLaserStrength = 2
SWEP.Primary.AimLaserColor = Color(100, 120, 255)

SWEP.SpreadFromProficiency = {0, 1}
SWEP.BurstSettings = {1, 1, 0}
SWEP.BurstRestTimes = {0, 0}

SWEP.Primary.ClipSize = 10
SWEP.Primary.DefaultClip = 10
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "ar2"


sound.Add({
    name = "CMB_EVO.AR2DMR.Fire",
    channel = CHAN_WEAPON,
    volume = 1.0,
    level = 100,
    pitch = 98,
    sound = "^npc/strider/strider_minigun.wav"
})

sound.Add({
    name = "CMB_EVO.AR2DMR.ChargeUp",
    channel = CHAN_WEAPON,
    volume = 0.5,
    level = 80,
    pitch = 100,
    sound = "npc/sniper/reload1.wav"
})

sound.Add({
    name = "CMB_EVO.AR2DMR.ChargeEnd",
    channel = CHAN_WEAPON,
    volume = 0.5,
    level = 80,
    pitch = 92,
    sound = "weapons/ar2/ar2_reload_push.wav"
})