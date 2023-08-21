AddCSLuaFile()

ENT.Base                     = "cmbevo_nade"
ENT.PrintName                = "Eastern Dispatch Grenade"
ENT.Model                    = "models/cmb_evo/weapons/w_nade_impact.mdl"
ENT.RenderGroup              = RENDERGROUP_BOTH

ENT.InstantFuse = false
ENT.ImpactFuse = true
ENT.Delay = 0

ENT.ExplodeSounds = {
    "^cmb_evo/weapons/frag_explode-1.wav",
    "^cmb_evo/weapons/frag_explode-2.wav",
    "^cmb_evo/weapons/frag_explode-3.wav",
}

local clr = Color(255, 128, 0, 150)

function ENT:OnInitialize()
    if SERVER then
        self.Trail = util.SpriteTrail(self, 1, clr, true, 2, 0, 0.5, 2, "sprites/laserbeam")
    end
end

function ENT:Detonate()
    local attacker = IsValid(self:GetOwner()) and self:GetOwner() or self

    util.BlastDamage(self, attacker, self:GetPos(), 200, 35)

    local fx = EffectData()
    fx:SetOrigin(self:GetPos())

    if self:WaterLevel() > 0 then
        util.Effect("WaterSurfaceExplosion", fx)
    else
        util.Effect("HelicopterMegaBomb", fx)
    end

    self:EmitSound(table.Random(self.ExplodeSounds), 125, 110)
end

function ENT:Draw()
    self:DrawModel()
end

local glow = Material("sprites/light_glow02_add")
function ENT:DrawTranslucent()
    render.SetMaterial(glow)
    render.DrawSprite(self:GetAttachment(1).Pos, 24, 24, clr)
end