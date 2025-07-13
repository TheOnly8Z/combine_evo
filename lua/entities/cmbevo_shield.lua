AddCSLuaFile()

ENT.Type                     = "anim"
ENT.Base                     = "base_entity"
ENT.RenderGroup              = RENDERGROUP_BOTH

ENT.PrintName                = "Riot Shield"
ENT.Category                 = ""

ENT.Spawnable                = false
ENT.Model                    = "models/weapons/cmb_evo/riot_shield.mdl"

ENT.CollisionBoundsMin = Vector(-2.68 - 16, -16.22 - 16, -1.36)
ENT.CollisionBoundsMax = Vector(4.44 + 32, 16.35 + 16, 53.52)

function ENT:SetupDataTables()
    self:NetworkVar("Vector", 0, "VisualOffset")
end

if SERVER then
    function ENT:Initialize()
        self:SetModel(self.Model)
        -- self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType( MOVETYPE_NONE )
        self:PhysicsInitBox(Vector(2, -16, -1.36), Vector(8, 16, 53.52), "metal")
        self:SetCollisionBounds(self.CollisionBoundsMin, self.CollisionBoundsMax)
        self:DrawShadow(false)
        self:AddEFlags(EFL_DONTBLOCKLOS)
        self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
        self.mmRHAe = 0.75
        -- self:EnableCustomCollisions(true)
    end

    function ENT:FlinchOwner()
        local owner = self:GetOwner()
        if IsValid(owner) and owner:IsNPC() and not owner:HasCondition(COND.NPC_FREEZE) then
            owner:SetLayerCycle( 0, 0 )
            owner:RestartGesture(owner:GetSequenceActivity(owner:LookupSequence("flinchshield")), true, true)
            owner:SetLayerWeight( 0, 10 )

            owner:SetCondition(COND.NPC_FREEZE)

            timer.Simple(1, function()
                if IsValid(owner) then
                    owner:SetCondition(COND.NPC_UNFREEZE)
                 end
            end)
        end
    end

    function ENT:OnDestroyed()
        local owner = self:GetOwner()
        owner:RemoveGesture(owner:GetSequenceActivity(owner:LookupSequence("gesture_shield")))

        self:FlinchOwner()

        self:EmitSound("physics/glass/glass_sheet_break1.wav", 75, 90, 1, CHAN_ITEM)

        local eff = EffectData()
        eff:SetOrigin(self:LocalToWorld(Vector(0, 0, 32) + self:GetVisualOffset()))
        eff:SetNormal(self:GetForward())
        eff:SetRadius(32)
        eff:SetMagnitude(4)
        util.Effect("Sparks", eff)

        SafeRemoveEntity(self)
    end

    function ENT:OnTakeDamage(dmginfo)
        local attacker = dmginfo:GetAttacker()
        local inflictor = dmginfo:GetInflictor()

        -- Disable friendly fire
        local owner = self:GetOwner()
        if IsValid(owner) and owner:IsNPC() and owner:Disposition(attacker) == D_LI then
            return 0
        end

        if IsValid(inflictor) and inflictor:IsPlayer() and IsValid(attacker:GetActiveWeapon()) then
            inflictor = attacker:GetActiveWeapon()
        end
        -- if inflictor.ArcticTacRP then
        --     dmginfo:ScaleDamage(inflictor:GetValue("ArmorBonus"))
        -- end

        -- Resist buckshot and melee
        if dmginfo:IsDamageType(DMG_CLUB) or dmginfo:IsDamageType(DMG_SLASH) or dmginfo:GetDamageType() == DMG_GENERIC then
            dmginfo:ScaleDamage(0.5)
        elseif dmginfo:IsDamageType(DMG_BUCKSHOT) then
            dmginfo:ScaleDamage(1.25)
        end

        self:SetHealth(self:Health() - dmginfo:GetDamage())
        if self:Health() <= 0 then
            self:OnDestroyed()
        else
            self:EmitSound("physics/glass/glass_impact_bullet" .. math.random(1, 4) .. ".wav", 70, Lerp(dmginfo:GetDamage() / 35, 100, 90))
            if (self.NextFlinch or 0) < CurTime() and dmginfo:IsDamageType(DMG_BUCKSHOT) then -- or math.random() * self:GetMaxHealth() * 1.5 < dmginfo:GetDamage()
                self:FlinchOwner()
                self.NextFlinch = CurTime() + 2.5 -- math.Rand(1, dmginfo:IsDamageType(DMG_BUCKSHOT) and 1.5 or Lerp(dmginfo:GetDamage() / 50, 4, 1.5))
            end
        end

        return dmginfo:GetDamage()
    end
end

function ENT:DrawTranslucent(flags)
    if IsValid(self:GetParent()) then
        self:SetRenderOrigin(self:LocalToWorld(self:GetVisualOffset()))
    else
        self:SetRenderOrigin()
    end
    self:DrawModel()
    -- self:SetRenderOrigin(nil)
end

--[[]
-- I wrote all this complicated shit before realizing it won't be run while parented
function ENT:TestCollision(startpos, delta, isbox, extents, mask)

    local dir = delta:GetNormalized()
    local e = self --IsValid(self:GetOwner()) and self:GetOwner() or self
    local p = e:WorldSpaceCenter()
    local n = e:GetForward()

    local d = p:Dot(-n)
    local t = -(d + startpos:Dot(n)) / dir:Dot(n)

    local out = startpos + t * dir

    return {
        HitPos = out,
        Fraction = t / delta:Length(),
        normal = self:GetForward(),
    }
end
]]