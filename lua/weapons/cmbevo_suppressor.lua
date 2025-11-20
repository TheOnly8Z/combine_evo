AddCSLuaFile()

SWEP.Base = "cmbevo_base"

SWEP.PrintName = "Combine Suppressor"

SWEP.WorldModel = "models/cmb_evo/weapons/w_zr68.mdl"
SWEP.HoldType = "shotgun"

SWEP.Primary.ShootSound = "CMB_EVO.Suppressor.FireLoop"
SWEP.Primary.ShootSoundLooping = true
SWEP.Primary.ShootSoundLoopStop = "CMB_EVO.Suppressor.FireLoopStop"

SWEP.Primary.Damage = 3
SWEP.Primary.Num = 2
SWEP.Primary.Cone = 0.035
SWEP.Primary.Delay = 0.1
SWEP.Primary.Tracer = 1
SWEP.Primary.TracerName = "AR2Tracer"
SWEP.Primary.EjectName = false
SWEP.Primary.HullSize = 4

SWEP.Primary.AimTime = 0.75
SWEP.Primary.AimTimeThreshold = 0
SWEP.Primary.AimBlindFireChance = 1
SWEP.Primary.AimIgnoreCover = true

SWEP.Primary.WindupTime = 0
SWEP.Primary.WindupSound = "CMB_EVO.Suppressor.FireLoopStart"

SWEP.Primary.AimLaserStrength = 3
SWEP.Primary.AimLaserColor = Color(0, 100, 255, 50)

SWEP.SpreadFromProficiency = {0, 10}
SWEP.BurstSettings = {1, 1, 0}
SWEP.BurstRestTimes = {4, 6}

SWEP.Primary.ClipSize = 40
SWEP.Primary.DefaultClip = 40
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "ar2"

function SWEP:GetCapabilities()
    if self:GetAimTime() > 0 then
        return 0
    end
    return bit.bor(CAP_WEAPON_RANGE_ATTACK1, CAP_INNATE_RANGE_ATTACK1)
end

sound.Add({
    name = "CMB_EVO.Suppressor.FireLoop",
    channel = CHAN_WEAPON,
    volume = 1.0,
    level = 140,
    pitch = 108,
    sound = "^npc/combine_gunship/gunship_fire_loop1.wav"
})

sound.Add({
    name = "CMB_EVO.Suppressor.FireLoopStop",
    channel = CHAN_WEAPON,
    volume = 1.0,
    level = 100,
    pitch = 108,
    sound = "npc/combine_gunship/attack_stop2.wav"
})

sound.Add({
    name = "CMB_EVO.Suppressor.FireLoopStart",
    channel = CHAN_WEAPON,
    volume = 1.0,
    level = 100,
    pitch = 108,
    sound = "npc/combine_gunship/attack_start2.wav"
})

SWEP.CustomActivityTranslation = true
SWEP.ActivityTranslateAI = {
    [ACT_IDLE]							= ACT_DOD_STAND_IDLE,
    [ACT_IDLE_RELAXED]					= ACT_DOD_STAND_IDLE,
    [ACT_IDLE_STIMULATED]				= ACT_DOD_STAND_AIM_MG,
    [ACT_IDLE_AGITATED]					= ACT_DOD_STAND_AIM_MG,
    [ACT_IDLE_STEALTH]					= ACT_DOD_STAND_AIM_MG,
    [ACT_IDLE_ANGRY]					= ACT_DOD_STAND_AIM_MG,
    [ACT_IDLE_AIM_RELAXED]				= ACT_DOD_STAND_AIM_MG,
    [ACT_IDLE_AIM_STIMULATED]			= ACT_DOD_STAND_AIM_MG,
    [ACT_IDLE_AIM_AGITATED]				= ACT_DOD_STAND_AIM_MG,
    [ACT_IDLE_AIM_STEALTH]				= ACT_DOD_STAND_AIM_MG,
    [ACT_WALK]							= ACT_DOD_WALK_IDLE_MG,
    [ACT_WALK_RELAXED]					= ACT_DOD_WALK_IDLE_MG,
    [ACT_WALK_STIMULATED]				= ACT_DOD_WALK_AIM_MG,
    [ACT_WALK_AGITATED]					= ACT_DOD_WALK_AIM_MG,
    [ACT_WALK_STEALTH]					= ACT_DOD_WALK_AIM_MG,
    [ACT_WALK_AIM]						= ACT_DOD_WALK_AIM_MG,
    [ACT_WALK_AIM_RELAXED]				= ACT_DOD_WALK_AIM_MG,
    [ACT_WALK_AIM_STIMULATED]			= ACT_DOD_WALK_AIM_MG,
    [ACT_WALK_AIM_AGITATED]				= ACT_DOD_WALK_AIM_MG,
    [ACT_WALK_AIM_STEALTH]				= ACT_DOD_WALK_AIM_MG,
    [ACT_WALK_CROUCH]					= ACT_WALK_CROUCH_RIFLE,
    [ACT_WALK_CROUCH_AIM]				= ACT_WALK_CROUCH_RIFLE,
    [ACT_RUN]							= ACT_DOD_RUN_IDLE_MG,
    [ACT_RUN_RELAXED]					= ACT_DOD_RUN_IDLE_MG,
    [ACT_RUN_STIMULATED]				= ACT_DOD_RUN_AIM_MG,
    [ACT_RUN_AGITATED]					= ACT_DOD_RUN_AIM_MG,
    [ACT_RUN_STEALTH]					= ACT_DOD_RUN_AIM_MG,
    [ACT_RUN_AIM]						= ACT_DOD_RUN_AIM_MG,
    [ACT_RUN_AIM_RELAXED]				= ACT_DOD_RUN_AIM_MG,
    [ACT_RUN_AIM_STIMULATED]			= ACT_DOD_RUN_AIM_MG,
    [ACT_RUN_AIM_AGITATED]				= ACT_DOD_RUN_AIM_MG,
    [ACT_RUN_AIM_STEALTH]				= ACT_DOD_RUN_AIM_MG,
    [ACT_RUN_CROUCH]					= ACT_RUN_CROUCH_RIFLE,
    [ACT_RUN_CROUCH_AIM]				= ACT_RUN_CROUCH_RIFLE,
    [ACT_RELOAD]						= ACT_DOD_RELOAD_FG42,
    [ACT_RELOAD_LOW]					= ACT_DOD_RELOAD_PRONE_DEPLOYED_MG34,
    [ACT_RANGE_ATTACK1]					= ACT_DOD_PRIMARYATTACK_DEPLOYED_MG,
    [ACT_RANGE_ATTACK1_LOW]				= ACT_DOD_PRIMARYATTACK_PRONE_MG,
    [ACT_GESTURE_RANGE_ATTACK1]			= ACT_DOD_PRIMARYATTACK_MG,
    [ACT_COVER_LOW]						= ACT_DOD_CROUCH_AIM_MG,
    [ACT_CROUCHIDLE]					= ACT_DOD_CROUCH_AIM_MG,
    [ACT_RANGE_AIM_LOW]					= ACT_DOD_CROUCH_AIM_MG,
    [ACT_CROUCHIDLE_STIMULATED]			= ACT_DOD_CROUCH_AIM_MG,
    [ACT_CROUCHIDLE_AIM_STIMULATED]		= ACT_DOD_CROUCH_AIM_MG,
    [ACT_CROUCHIDLE_AGITATED]			= ACT_DOD_CROUCH_AIM_MG,
}