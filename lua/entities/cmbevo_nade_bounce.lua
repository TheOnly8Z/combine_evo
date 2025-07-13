AddCSLuaFile()

ENT.Base                     = "cmbevo_nade"
ENT.PrintName                = "Bounce Grenade"
ENT.Model                    = "models/Items/combine_rifle_ammo01.mdl"
ENT.RenderGroup              = RENDERGROUP_BOTH

ENT.InstantFuse = false
ENT.ImpactFuse = true
ENT.Delay = 0.5

ENT.Sticky = false

ENT.PhysicsSounds = true

ENT.ExplodeSounds = {
    "weapons/stunstick/alyx_stunner1.wav",
    "weapons/stunstick/alyx_stunner2.wav",
}

DEFINE_BASECLASS(ENT.Base)

local clr = Color(255, 255, 0, 150)

function ENT:OnInitialize()
    if SERVER then
        self.Trail = util.SpriteTrail(self, 0, clr, true, 4, 0, 0.3, 2, "sprites/laserbeam")
    end
end

function ENT:Detonate()
    -- local attacker = IsValid(self:GetOwner()) and self:GetOwner() or self
    -- util.BlastDamage(self, attacker, self:GetPos(), 328, 25)

    local fx = EffectData()
    -- fx:SetMagnitude(10)
    -- fx:SetScale(1)
    fx:SetEntity(self)

    for _, ent in pairs(ents.FindInSphere(self:GetPos(), 328)) do
        if not IsValid(ent:GetPhysicsObject()) then continue end
        local tr = util.TraceLine({
            start = ent:WorldSpaceCenter(),
            endpos = self:GetPos(),
            filter = {self, ent},
            mask = MASK_SHOT
        })
        if tr.Fraction == 1 then
            local f = Lerp(((ent:GetPos() - self:GetPos()):Length() / 328) ^ 2, 1, 0.25)
            if ent:IsNPC() or ent:IsPlayer() then
                -- if ent:IsPlayer() then
                --     ent:ScreenFade(SCREENFADE.IN, Color(255, 255, 150, 75), 0.25, 0.1)
                -- end
                ent:SetVelocity((ent:GetPos() - self:GetPos()):GetNormalized() * f * (ent:IsOnGround() and 1 or 0.1) * (ent == self:GetOwner() and 2000 or 750) + Vector(0, 0, 350))
            elseif (ent:GetPhysicsObject():GetVolume() or 0) >= 32 then
                ent:GetPhysicsObject():ApplyForceCenter((ent:GetPos() - self:GetPos()):GetNormalized() * f * 2000)
            end

            fx:SetOrigin(ent:WorldSpaceCenter())
            util.Effect("PhyscannonImpact", fx)
        end
    end

    self:EmitSound(table.Random(self.ExplodeSounds), 110, 90)
end

function ENT:Draw()
    self:DrawModel()
end

function ENT:PhysicsCollide(data, collider)
    BaseClass.PhysicsCollide(self, data, collider)
end

local glow = Material("sprites/light_glow02_add")
function ENT:DrawTranslucent()
    render.SetMaterial(glow)
    render.DrawSprite(self:GetPos(), 32, 32, clr)
end