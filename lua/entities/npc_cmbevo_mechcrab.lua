AddCSLuaFile()

ENT.PrintName = "Combine Mechcrab"
ENT.Base = "base_ai"
ENT.m_iClass = CLASS_COMBINE

if CLIENT then return end

-- Re-implementing the entire headcrab for the sole purpose of not having to call NPC:AddEntityRelationship() is...
-- A questionable decision

-- https:--github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/server/hl2/npc_headcrab.cpp

-- Most comments are copied from engine code

function ENT:Initialize()
    self:SetModel("models/cmb_evo/combinecrab.mdl")
    self:SetHullType(HULL_TINY)
    self:SetHullSizeNormal()
    self:SetSolid(SOLID_BBOX)
    self:AddSolidFlags(FSOLID_NOT_STANDABLE)
    self:SetMoveType(MOVETYPE_STEP)
    self:SetCollisionGroup( COLLISION_GROUP_NPC ) -- HL2COLLISION_GROUP_HEADCRAB ???
    self:SetViewOffset(Vector(6, 0, 11))
    self:SetBloodColor(BLOOD_COLOR_GREEN)
    self:SetFOV(0.5)
    self:SetNPCState(NPC_STATE_NONE)

    --[[ -- TODO maybe implement this
    -- Are we starting hidden?
    if ( m_spawnflags & SF_HEADCRAB_START_HIDDEN )
    {
        m_bHidden = true;
        AddSolidFlags( FSOLID_NOT_SOLID );
        SetRenderColorA( 0 );
        m_nRenderMode = kRenderTransTexture;
        AddEffects( EF_NODRAW );
    }
    else
    {
        m_bHidden = false;
    }
    ]]

    self:CapabilitiesAdd(bit.bor(CAP_MOVE_GROUND, CAP_INNATE_RANGE_ATTACK1, CAP_SQUAD))
    self:SetHealth(10)
    self:SetMaxHealth(10)
end

function ENT:Leap(jump_vel)
    print("leap ", jump_vel)

    self:SetCondition(COND.FLOATING_OFF_GROUND)
    self:SetGroundEntity(NULL)
    self:SetSaveValue("m_flIgnoreWorldCollisionTime", CurTime() + 0.5)
    if self:HasHeadroom() then
        -- Take him off ground so engine doesn't instantly reset FL_ONGROUND.
        self:SetPos(self:GetPos() + Vector(0, 0, 1))
    end

    --self:SetAbsVelocity(jump_vel)
    self:SetVelocity(jump_vel)

    self:SetSaveValue("m_bMidJump", true)
    self.DoJumpTouch = true

    self:NextThink(CurTime())
end

function ENT:JumpAttack(pos, thrown)
    local jump_vel
    if pos then
        local gravity = math.max(1, GetConVar("sv_gravity"):GetFloat())
        local height = math.Clamp(pos.z - self:GetPos().z, 16, thrown and 400 or 120)
        -- overshoot the jump by an additional 8 inches
        -- NOTE: This calculation jumps at a position INSIDE the box of the enemy (player)
        -- so if you make the additional height too high, the crab can land on top of the
        -- enemy's head.  If we want to jump high, we'll need to move vecPos to the surface/outside
        -- of the enemy's box.
        local add_height = 0
        if height < 32 then
            add_height = 8
        end
        height = height + add_height

        -- NOTE: This equation here is from vf^2 = vi^2 + 2*a*d
        local speed = math.sqrt(gravity * height * 2)
        local time = speed / gravity

        -- add in the time it takes to fall the additional height
        -- So the impact takes place on the downward slope at the original height
        time = time + math.sqrt((add_height * 2) / gravity)

        -- Scale the sideways velocity to get there at the right time
        jump_vel = pos - self:GetPos()
        jump_vel:Div(time)

        -- Speed to offset gravity at the desired height.
        jump_vel.z = speed

        -- Don't jump too far/fast.
        local jump_speed = jump_vel:Length()
        local max_speed = thrown and 1000 or 650
        if jump_speed > max_speed then
            jump_vel:Mul(max_speed / jump_speed)
        end
    else
        -- Jump hop, don't care where.
        local f, u = self:GetForward(), self:GetUp()
        jump_vel = Vector(f.x, f.y, u.z) * 350
    end

    self:AttackSound()
    self:Leap(jump_vel)
end

function ENT:SetBurrowed(state)
    -- TODO
    --[[
    if ( bBurrowed )
	{
		AddEffects( EF_NODRAW );
		AddFlag( FL_NOTARGET );
		m_spawnflags |= SF_NPC_GAG;
		AddSolidFlags( FSOLID_NOT_SOLID );
		m_takedamage = DAMAGE_NO;
		m_flFieldOfView = HEADCRAB_BURROWED_FOV;

		SetState( NPC_STATE_IDLE );
		SetActivity( (Activity) ACT_HEADCRAB_BURROW_IDLE );
	}
	else
	{
		RemoveEffects( EF_NODRAW );
		RemoveFlag( FL_NOTARGET );
		m_spawnflags &= ~SF_NPC_GAG;
		RemoveSolidFlags( FSOLID_NOT_SOLID );
		m_takedamage = DAMAGE_YES;
		m_flFieldOfView	= HEADCRAB_UNBURROWED_FOV;
	}

	m_bBurrowed = bBurrowed;
    ]]
end

--
-- Built in hooks
--
function ENT:Think()
    if self:GetNPCState() == NPC_STATE_COMBAT and math.Rand(0, 5) < 0.1 then
        self:IdleSound()
    end

    self:SetMaxYawSpeed(self:MaxYawSpeed())

    -- Check RangeAttack1Conditions here i guess?


    -- Think every frame so the player sees the headcrab where he actually is...
    if self:GetInternalVariable("m_bMidJump") == true then
        if self:IsOnGround() then
            self:NextThink(CurTime() + 0.1)
            return true
        end
        self:NextThink(CurTime())
        return true
    else

    end
    -- Something something burrow
end

function ENT:OnChangeActivity(act)
    -- If this crab is starting to walk or idle, pick a random point within
    -- the animation to begin. This prevents lots of crabs being in lockstep.
    local rand
    if act == ACT_IDLE then
        rand = 0.75
    elseif act == ACT_RUN then
        rand = 0.25
    end
    if rand then
        self:SetCycle(math.Rand(0, rand))
    end
end

function ENT:HandleAnimEvent(event, event_time, cycle, event_type, options)
    local eventname = util.GetAnimEventNameByID(event)
    if eventname == "AE_HEADCRAB_JUMPATTACK" then
        -- Ignore if we're in mid air
        if self:GetInternalVariable("m_bMidJump") == true then return end

        local enemy = self:GetEnemy()

        if IsValid(enemy) then
            if self:GetInternalVariable("m_bCommittedToJump") then
                self:JumpAttack(self:GetInternalVariable("m_vecCommittedJumpPos"))
            else
                self:JumpAttack(enemy:EyePos())
            end
        else
            self:JumpAttack()
        end
        return
    elseif eventname == "AE_HEADCRAB_CEILING_DETACH" then
        self:SetMoveType(MOVETYPE_STEP)
        self:RemoveFlags(FL_FLY + FL_ONGROUND)
        self:SetAbsVelocity(Vector(0, 0, -128))
        return
    elseif eventname == "AE_HEADCRAB_JUMP_TELEGRAPH" then
        local enemy = self:GetEnemy()

        if IsValid(enemy) then
            -- Once we telegraph, we MUST jump. This is also when commit to what point
            -- we jump at. Jump at our enemy's eyes.
            self:SetSaveValue("m_bCommittedToJump", true)
            self:SetSaveValue("m_vecCommittedJumpPos", enemy:EyePos())
        end
        return
    end
    -- TODO: handle AE_HEADCRAB_BURROW_IN, AE_HEADCRAB_BURROW_IN_FINISH, and AE_HEADCRAB_BURROW_OUT
end

function ENT:OnTakeDamage(dmginfo)
    if dmginfo:IsDamageType(DMG_ACID) then
        return 0
    end

    self:SetHealth(self:Health() - dmginfo:GetDamage())
    if self:Health() <= 0 then
        self:DoDeath(dmginfo)
    end
    return dmginfo:GetDamage()
end

function ENT:Touch(ent)
    if not self.DoJumpTouch then return end

    self:SetSaveValue("m_bMidJump", false)

    if self:Disposition(ent) == D_HT then
        -- Don't hit if back on ground
        if not self:OnGround() then
            self:BiteSound()
            self:TouchDamage(ent)
            self:SetSaveValue("m_bAttackFailed", false)
        else
            self:ImpactSound()
        end
    elseif not self:IsOnGround() then
        if not ent:IsSolid() then
            return -- Touching a trigger or something.
        end

        -- just ran into something solid, so the attack probably failed.  make a note of it
        -- so that when the attack is done, we'll delay attacking for a while so we don't
        -- just repeatedly leap at the enemy from a bad location.
        self:SetSaveValue("m_bAttackFailed", true)

        if  CurTime() < (self:GetInternalVariable("m_flIgnoreWorldCollisionTime") or 0) then
            -- Headcrabs try to ignore the world, static props, and friends for a
            -- fraction of a second after they jump. This is because they often brush
            -- doorframes or props as they leap, and touching those objects turns off
            -- this touch function, which can cause them to hit the player and not bite.
            -- A timer probably isn't the best way to fix this, but it's one of our
            -- safer options at this point (sjb).
            return
        end

        -- Shut off the touch function.
        self.DoJumpTouch = false
    end
end
--
-- Utility
--
function ENT:DoDeath(dmginfo)
    local attacker = dmginfo:GetAttacker()
    local inflictor = dmginfo:GetInflictor()
    self.Dead = true
    self:SetSaveValue("m_lifeState", 2) -- LIFE_DEAD
    if IsValid(inflictor) then
        gamemode.Call("OnNPCKilled", self, attacker, inflictor, dmginfo)
    end
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    if IsValid(attacker) then -- Someone else killed me
        self:TriggerOutput("OnDeath", attacker)
        attacker:Fire("KilledNPC", "", 0, self, self) -- Allows player companions (npc_citizen) to respond to kill
    else
        self:TriggerOutput("OnDeath", self)
    end

    if not dmginfo:IsDamageType(DMG_REMOVENORAGDOLL) then
        local corpse = ents.Create("prop_ragdoll")
        self.Corpse = corpse
        corpse:SetModel(self:GetModel())
        corpse:SetPos(self:GetPos())
        corpse:SetAngles(self:GetAngles())
        corpse:Spawn()
        corpse:Activate()
        corpse:SetSkin(self:GetSkin())
        for i = 0, self:GetNumBodyGroups() do
            corpse:SetBodygroup(i, self:GetBodygroup(i))
        end
        corpse:SetColor(self:GetColor())
        corpse:SetMaterial(self:GetMaterial())

        if GetConVar("ai_serverragdolls"):GetInt() == 1 then
            corpse:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE)
            undo.ReplaceEntity(self, corpse)
        else
            corpse:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
        end
        cleanup.ReplaceEntity(self, corpse)

        if self:IsOnFire() then
            corpse:Ignite(math.Rand(8, 10), 0)
        end

        if dmginfo:IsDamageType(DMG_DISSOLVE) or (inflictor:GetClass() == "prop_combine_ball") then
            corpse:Dissolve(0, 1)
        end

        local useLocalVel = dmginfo:IsDamageType(DMG_BULLET) ~= 0 and dmginfo:GetDamageForce() ~= vector_origin or false
        local dmgForce = dmginfo:GetDamageForce() / 5 + self:GetMoveVelocity() + self:GetVelocity()
        local dmgPos = dmginfo:GetDamagePosition()
        local totalSurface = 0
        local physCount = corpse:GetPhysicsObjectCount()
        for childNum = 0, physCount - 1 do -- 128 = Bone Limit
            local childPhysObj = corpse:GetPhysicsObjectNum(childNum)
            if IsValid(childPhysObj) then
                totalSurface = totalSurface + childPhysObj:GetSurfaceArea()
                local childPhysObj_BonePos, childPhysObj_BoneAng = self:GetBonePosition(corpse:TranslatePhysBoneToBone(childNum))
                if childPhysObj_BonePos then
                    childPhysObj:SetAngles(childPhysObj_BoneAng)
                    childPhysObj:SetPos(childPhysObj_BonePos)
                    childPhysObj:SetVelocity(dmgForce / math.max(1, (useLocalVel and childPhysObj_BonePos:Distance(dmgPos) / 12) or 1))
                -- If it's 1, then it's likely a regular physics model with no bones
                elseif physCount == 1 then
                    childPhysObj:SetVelocity(dmgForce / math.max(1, (useLocalVel and corpse:GetPos():Distance(dmgPos) / 12) or 1))
                end
            end
        end

        corpse:Fire("FadeAndRemove", "", 10)

        hook.Call("CreateEntityRagdoll", nil, self, corpse)
    end

    self:Remove()
end

function ENT:HasHeadroom()
    return true
end

function ENT:TouchDamage(ent)
    local dmginfo = DamageInfo()
    dmginfo:SetAttacker(self)
    dmginfo:SetInflictor(self)
    dmginfo:SetDamageType(DMG_SLASH)
    local dmg = GetConVar("sk_headcrab_melee_dmg"):GetFloat()
    dmginfo:SetDamage(dmg)
    dmginfo:SetDamagePosition(self:GetPos())
    dmginfo:SetDamageForce(self:GetVelocity():GetNormalized() * dmg * (75 * 4) * GetConVar("phys_pushscale"):GetFloat())
    ent:TakeDamageInfo(dmginfo)
end

function ENT:MaxYawSpeed()
    local act = self:GetActivity()
    if act == ACT_IDLE then
        return 30
    elseif act == ACT_RUN or ACT == ACT_WALK then
        return 20
    elseif act == ACT_TURN_LEFT or act == ACT_TURN_RIGHT then
        return 15
    elseif ACT_RANGE_ATTACK1 then
        return 15
        -- local task = self:GetCurrentSchedule():GetTask()
        -- if task.iTask == TASK_HEADCRAB_JUMP_FROM_CANISTER then
        --     return 15
        -- end
    end
    return 30
end

--
-- Sounds
--
function ENT:AttackSound()
end

function ENT:TelegraphSound()
end

function ENT:IdleSound()
end

function ENT:BiteSound()
end

function ENT:ImpactSound()
end

local HEADCRAB_MIN_JUMP_DIST = 48
local HEADCRAB_MAX_JUMP_DIST = 256
function ENT:RangeAttack1Conditions(dot, dist)
    if CurTime() < (self:GetInternalVariable("m_flNextAttack") or 0) then
        return COND.NONE
    end

    if not self:IsOnGround() then
        return COND.NONE
    end

    if dot < 0.65 then
        return COND.NOT_FACING_ATTACK
    end

    if dist < HEADCRAB_MIN_JUMP_DIST then
        return COND.TOO_CLOSE_TO_ATTACK
    end
    if dist > HEADCRAB_MAX_JUMP_DIST then
        return COND.TOO_FAR_TO_ATTACK
    end
end