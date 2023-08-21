AddCSLuaFile()

SWEP.Base = "cmbevo_base"

SWEP.PrintName = "ZR-68"

SWEP.WorldModel = "models/cmb_evo/weapons/w_zr68.mdl" -- TODO model
SWEP.HoldType = "ar2"

SWEP.Primary.ShootSound = "CMB_EVO.ZR68.Fire"
SWEP.Secondary.ShootSound = "CMB_EVO.TGS12.Fire"

SWEP.Primary.Damage = 3
SWEP.Primary.Num = 1
SWEP.Primary.Cone = 0.012
SWEP.Primary.Delay = 0.1
SWEP.Primary.HullSize = 0

SWEP.Primary.Tracer = 2
SWEP.Primary.TracerName = "Tracer"
SWEP.Primary.EjectName = "RifleShellEject"

SWEP.SpreadFromProficiency = {2, 12}
SWEP.BurstSettings = {3, 5, 0.1}
SWEP.BurstRestTimes = {0.6, 1}

SWEP.Primary.ClipSize = 20
SWEP.Primary.DefaultClip = 20
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "ar2"

SWEP.Secondary.Damage = 3
SWEP.Secondary.Num = 8
SWEP.Secondary.Cone = 0.1
SWEP.Secondary.Delay = 0.5
SWEP.Secondary.HullSize = 4
SWEP.Secondary.Tracer = 2
SWEP.Secondary.TracerName = "Tracer"
SWEP.Secondary.EjectName = "ShotgunShellEject"

SWEP.Secondary.ClipSize = 4
SWEP.Secondary.DefaultClip = 4
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "buckshot"

DEFINE_BASECLASS(SWEP.Base)

function SWEP:GetCapabilities()
    return bit.bor(CAP_WEAPON_RANGE_ATTACK1, CAP_INNATE_RANGE_ATTACK1, CAP_WEAPON_RANGE_ATTACK2, CAP_INNATE_RANGE_ATTACK2)
end

function SWEP:GetNPCBulletSpread(prof)
    if self:GetNextSecondaryFire() > CurTime() then
        return 0
    end
    if self.SpreadFromProficiency then
        return Lerp(prof / 4, self.SpreadFromProficiency[2], self.SpreadFromProficiency[1])
    end
end

sound.Add({
    name = "CMB_EVO.ZR68.Fire",
    channel = CHAN_WEAPON,
    volume = 1.0,
    level = 110,
    pitch = {95, 100},
    sound = "^cmb_evo/weapons/zr68-fire.wav"
})

sound.Add({
    name = "CMB_EVO.TGS12.Fire",
    channel = CHAN_WEAPON,
    volume = 1.0,
    level = 110,
    pitch = 100,
    sound = "^cmb_evo/weapons/tgs12-fire.wav"
})