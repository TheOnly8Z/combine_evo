AddCSLuaFile()

ENT.Base                     = "cmbevo_nade"
ENT.PrintName                = "Eastern Dispatch Grenade"
ENT.Model                    = "models/kali/weapons/nt/explosives/grenade.mdl"

ENT.InstantFuse = false
ENT.ImpactFuse = true
ENT.Delay = 0

ENT.ExplodeSounds = {
    "^weapons/explode3.wav",
    "^weapons/explode4.wav",
    "^weapons/explode5.wav",
}

local clr = Color(255, 128, 0, 200)

function ENT:OnInitialize()
    if SERVER then
        self.Trail = util.SpriteTrail(self, 0, clr, true, 2, 0.5, 0.5, 2, "sprites/laserbeam")
    end
end

function ENT:Detonate()
    local attacker = IsValid(self:GetOwner()) and self:GetOwner() or self

    util.BlastDamage(self, attacker, self:GetPos(), 200, 40)

    local fx = EffectData()
    fx:SetOrigin(self:GetPos())

    if self:WaterLevel() > 0 then
        util.Effect("WaterSurfaceExplosion", fx)
    else
        util.Effect("HelicopterMegaBomb", fx)
    end

    self:EmitSound(table.Random(self.ExplodeSounds), 125, 125)

    self:Remove()
end

local glow = Material("sprites/light_glow02_add")
function ENT:DrawTranslucent()
    self:DrawModel()
    render.SetMaterial(glow)
    render.DrawSprite(self:GetPos(), 24, 24, clr)
end