-----------------------------------------------------------
-- Riot Police
-----------------------------------------------------------

local shield_health = CreateConVar("cmbevo_riot_shield_health", 70, FCVAR_ARCHIVE, "[Riot Police] Durability of riot shield. 0 - Unbreakable.", 0)

NPC.Name = "Riot Police"
NPC.Class = "npc_metropolice"
NPC.Model = "models/cmb_evo/police_riot.mdl"
NPC.Skin = 0
NPC.Weapons = {"weapon_stunstick"}
NPC.KeyValues = {}
NPC.Tags = {}
NPC.Proficiency = WEAPON_PROFICIENCY_POOR

local function makeshield(self)
    if not IsValid(self.CmbEvoShield) then
        self.CmbEvoShield = ents.Create( "cmbevo_shield" ) --
        self.CmbEvoShield:SetModel( "models/weapons/cmb_evo/riot_shield.mdl" )
        self.CmbEvoShield:SetOwner( self )
        self.CmbEvoShield:Spawn()
        self.CmbEvoShield:Activate()
        self.CmbEvoShield:AddEFlags( EFL_DONTBLOCKLOS )

        self.CmbEvoShield:SetMaxHealth(shield_health:GetInt())
        self.CmbEvoShield:SetHealth(shield_health:GetInt())

        self.CmbEvoShield:PhysicsInit( SOLID_NONE )
        self.CmbEvoShield:SetMoveType( MOVETYPE_NONE )
        self.CmbEvoShield:SetSolid( SOLID_NONE )

        local offsetPos = Vector(-2, -4, -25) --Vector( 14, -4, -10 )
        local trueOffset = Vector(10, 0, 10)
        local offsetAng = Angle( -100, 0, -80 )
        local att = self:LookupAttachment( "shield" )
        local attTab = self:GetAttachment(att)
        local newPos, newAng = LocalToWorld( offsetPos + trueOffset, offsetAng, attTab.Pos, attTab.Ang )

        self.CmbEvoShield:SetParent( self, att )
        self.CmbEvoShield:SetPos( newPos )
        self.CmbEvoShield:SetAngles( newAng )
        self.CmbEvoShield:SetVisualOffset(-trueOffset)

        self.CmbEvoShield:PhysicsInit( SOLID_VPHYSICS )
        self.CmbEvoShield:SetMoveType( MOVETYPE_VPHYSICS )
        self.CmbEvoShield:SetCollisionGroup( COLLISION_GROUP_WEAPON )

    end

end

function NPC:OnSpawn(ply)
    makeshield(self)
    self:RestartGesture(self:GetSequenceActivity(self:LookupSequence("gesture_shield")), true, false)
end


function NPC:OnDeath(attacker, inflictor)

    if IsValid(self.CmbEvoShield) then
        -- SafeRemoveEntity(self.CmbEvoShield)

        timer.Simple(0, function()
            if IsValid(self.CmbEvoShield) then
                self.CmbEvoShield:SetParent(NULL)
                self.CmbEvoShield:PhysicsInit( SOLID_VPHYSICS )
                self.CmbEvoShield:SetMoveType( MOVETYPE_VPHYSICS )
                self.CmbEvoShield:SetSolid( SOLID_VPHYSICS )
                self.CmbEvoShield:PhysWake()
            end
        end)
        SafeRemoveEntityDelayed(self.CmbEvoShield, 3)
    end
end