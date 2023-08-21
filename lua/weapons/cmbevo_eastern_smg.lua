AddCSLuaFile()

SWEP.Base = "cmbevo_base"

SWEP.PrintName = "MPN-45"

SWEP.WorldModel = "models/cmb_evo/weapons/w_mpn45.mdl"
SWEP.HoldType = "smg"

SWEP.Primary.ShootSound = "CMB_EVO.MPN45.Fire"

SWEP.Primary.Damage = 3
SWEP.Primary.Num = 1
SWEP.Primary.Cone = 0.02
SWEP.Primary.Delay = 0.07
SWEP.Primary.Tracer = 4
SWEP.Primary.TracerName = "Tracer"
SWEP.Primary.EjectName = "ShellEject"

SWEP.SpreadFromProficiency = {6, 18}
SWEP.BurstSettings = {8, 12, 0.07}
SWEP.BurstRestTimes = {0.5, 0.9}

SWEP.Primary.ClipSize = 40
SWEP.Primary.DefaultClip = 40
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "smg1"

sound.Add({
    name = "CMB_EVO.MPN45.Fire",
    channel = CHAN_WEAPON,
    volume = 1.0,
    level = 110,
    pitch = {90, 95},
    sound = "^cmb_evo/weapons/mpn45-fire.wav"
})