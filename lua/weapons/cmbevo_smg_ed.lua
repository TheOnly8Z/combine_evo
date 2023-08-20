AddCSLuaFile()

SWEP.Base = "cmbevo_base"

SWEP.PrintName = "MPN-45"

SWEP.WorldModel = "models/cmb_evo/weapons/w_mpn45.mdl"
SWEP.HoldType = "smg"

SWEP.Primary.ShootSound = "CMB_EVO.MPN45.Fire"

SWEP.Primary.Damage = 4
SWEP.Primary.Num = 1
SWEP.Primary.Cone = 0.015
SWEP.Primary.Delay = 0.075
SWEP.Primary.Tracer = 4
SWEP.Primary.TracerName = "Tracer"
SWEP.Primary.EjectName = false --"ShellEject"

SWEP.SpreadFromProficiency = {5, 15}
SWEP.BurstSettings = {8, 12, 0.075}
SWEP.BurstRestTimes = {0.5, 0.9}

SWEP.Primary.ClipSize = 35
SWEP.Primary.DefaultClip = 35
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