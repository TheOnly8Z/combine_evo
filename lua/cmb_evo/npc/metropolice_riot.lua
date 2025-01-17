-----------------------------------------------------------
-- Riot Police
-----------------------------------------------------------

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
        self.CmbEvoShield = ents.Create( "prop_physics" )
        self.CmbEvoShield:SetModel( "models/weapons/cmb_evo/riot_shield.mdl" )
        self.CmbEvoShield:SetOwner( self )
        self.CmbEvoShield:Spawn()
        self.CmbEvoShield:Activate()
        self.CmbEvoShield:AddEFlags( EFL_DONTBLOCKLOS )
        self.CmbEvoShield.mmRHAe = 0.6

        self.CmbEvoShield:PhysicsInit( SOLID_NONE )
        self.CmbEvoShield:SetMoveType( MOVETYPE_NONE )
        self.CmbEvoShield:SetSolid( SOLID_NONE )

        local offsetPos = Vector( 14, -4, -10 )
        local offsetAng = Angle( -100, 0, -80 )
        local att = self:LookupAttachment( "shield" )
        local attTab = self:GetAttachment(att)
        local newPos, newAng = LocalToWorld( offsetPos, offsetAng, attTab.Pos, attTab.Ang )

        self.CmbEvoShield:SetParent( self, att )
        self.CmbEvoShield:SetPos( newPos )
        self.CmbEvoShield:SetAngles( newAng )

        self.CmbEvoShield:SetColor( Color(0, 0, 0, 0) )
        self.CmbEvoShield:SetRenderMode(RENDERMODE_NONE)

        self.CmbEvoShield:PhysicsInit( SOLID_VPHYSICS )
        self.CmbEvoShield:SetMoveType( MOVETYPE_VPHYSICS )
        self.CmbEvoShield:SetCollisionGroup( COLLISION_GROUP_WEAPON )

        self.CmbEvoShieldVisual = ents.Create( "prop_physics" )
        self.CmbEvoShieldVisual:SetModel( "models/weapons/cmb_evo/riot_shield.mdl" )
        self.CmbEvoShieldVisual:SetOwner( self )
        self.CmbEvoShieldVisual:Spawn()
        self.CmbEvoShieldVisual:Activate()
        self.CmbEvoShieldVisual:AddEFlags( EFL_DONTBLOCKLOS )
        -- self.CmbEvoShieldVisual.mmRHAe = 0.35

        self.CmbEvoShieldVisual:PhysicsInit( SOLID_NONE )
        self.CmbEvoShieldVisual:SetMoveType( MOVETYPE_NONE )
        self.CmbEvoShieldVisual:SetSolid( SOLID_NONE )

        local offsetPos2 = Vector( -16, 0, -15 )
        local newPos2, newAng2 = LocalToWorld( offsetPos + offsetPos2, offsetAng, attTab.Pos, attTab.Ang )

        self.CmbEvoShieldVisual:SetParent( self, att )
        self.CmbEvoShieldVisual:SetPos( newPos2 )
        self.CmbEvoShieldVisual:SetAngles( newAng2 )

        self.CmbEvoShieldVisual:PhysicsInit( SOLID_VPHYSICS )
        self.CmbEvoShieldVisual:SetMoveType( MOVETYPE_VPHYSICS )
        self.CmbEvoShieldVisual:SetCollisionGroup( COLLISION_GROUP_WEAPON )
    end
end

function NPC:OnSpawn(ply)
    makeshield(self)
    self:RestartGesture(self:GetSequenceActivity(self:LookupSequence("gesture_shield")), true, false)
end


function NPC:OnDeath(attacker, inflictor)

    if IsValid(self.CmbEvoShieldVisual) then
        -- SafeRemoveEntity(self.CmbEvoShield)

        timer.Simple(0.1, function()
            if IsValid(self.CmbEvoShieldVisual) then
                self.CmbEvoShieldVisual:SetParent(NULL)
                self.CmbEvoShieldVisual:PhysicsInit( SOLID_VPHYSICS )
                self.CmbEvoShieldVisual:SetMoveType( MOVETYPE_VPHYSICS )
                self.CmbEvoShieldVisual:SetSolid( SOLID_VPHYSICS )
                self.CmbEvoShieldVisual:PhysWake()
            end
        end)
        SafeRemoveEntityDelayed(self.CmbEvoShieldVisual, 3)
    end
    if IsValid(self.CmbEvoShield) then
        SafeRemoveEntityDelayed(self.CmbEvoShield, 0)
    end

end