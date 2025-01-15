AddCSLuaFile()

ENT.Base                     = "cmbevo_nade"
ENT.PrintName                = "Frag Launcher Grenade"
ENT.Model                    = "models/Combine_Helicopter/helicopter_bomb01.mdl"
ENT.RenderGroup              = RENDERGROUP_BOTH

ENT.InstantFuse = false
ENT.ImpactFuse = false
ENT.StickyFuse = true
ENT.Delay = 0.25

ENT.Sticky = true

ENT.PhysicsSounds = true

ENT.ExplodeSounds = {
    "^cmb_evo/weapons/frag_explode-1.wav",
    "^cmb_evo/weapons/frag_explode-2.wav",
    "^cmb_evo/weapons/frag_explode-3.wav",
}

DEFINE_BASECLASS(ENT.Base)

local clr = Color(255, 0, 0, 150)

function ENT:OnInitialize()
    self:PhysicsInitSphere(4, "rubber")
    if SERVER then
        self:SetModelScale(0.25, 0)
        self.Trail = util.SpriteTrail(self, 0, clr, true, 2, 0, 0.3, 2, "sprites/laserbeam")
    end
end

function ENT:Detonate()
    local attacker = IsValid(self:GetOwner()) and self:GetOwner() or self

    util.BlastDamage(self, attacker, self:GetPos(), 180, 15)

    local fx = EffectData()
    fx:SetOrigin(self:GetPos())

    if self:WaterLevel() > 0 then
        util.Effect("WaterSurfaceExplosion", fx)
    else
        util.Effect("HelicopterMegaBomb", fx)
    end

    self:EmitSound(table.Random(self.ExplodeSounds), 110, 120)
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