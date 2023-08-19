AddCSLuaFile()

SWEP.Base = "cmbevo_base"

SWEP.PrintName = "Breach Shotgun"

SWEP.WorldModel = "models/weapons/tacint/w_tgs12.mdl" -- TODO find a super shorty model
SWEP.HoldType = "ar2"

SWEP.Primary.ShootSound = "^tacrp/weapons/tgs12/fire-1.wav"

SWEP.Primary.Damage = 2
SWEP.Primary.Num = 8
SWEP.Primary.Cone = 0.05
SWEP.Primary.Delay = 0.5

SWEP.SpreadFromProficiency = {0, 15}
SWEP.BurstSettings = {1, 1, 1}
SWEP.BurstRestTimes = {0.6, 0.9}

SWEP.Primary.ClipSize = 3
SWEP.Primary.DefaultClip = 3
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "buckshot"