AddCSLuaFile()

CMBEVO = {}


-----------------------------------------------------------
-- Load NPC modules
-----------------------------------------------------------
CMBEVO.NPC = {}

CMBEVO.NPC_Cache = {}

local function AddNPC(t, class)
    list.Set("NPC", class or t.Class, t)
end
local Category = "Combine Evo"

local function LoadNPCS()
    local dir = "cmb_evo/npc/"
    local files = file.Find(dir .. "*.lua", "LUA")
    for _, filename in ipairs(files) do
        NPC = {}

        include(dir .. filename)
        AddCSLuaFile(dir .. filename)

        local shortname = NPC.ShortName or string.sub(filename, 1, -5)

        NPC.ShortName = shortname

        CMBEVO.NPC[shortname] = NPC

        if not NPC.Ignore then
            NPC.KeyValues = NPC.KeyValues or {}
            NPC.KeyValues["squadname"] = NPC.Squad or "cmb_evo"
            NPC.KeyValues["parentname"] = "cmbevo_" .. shortname

            AddNPC({
                Name = NPC.Name,
                Class = NPC.Class,
                Category = NPC.Category or Category,
                Model = NPC.Model,
                Skin = NPC.Skin or 0,
                Health = NPC.Health,
                Weapons = NPC.Weapons,
                SpawnFlags = bit.bor(NPC.SpawnFlags or 0, 8192), -- "SF_NPC_NO_WEAPON_DROP"
                KeyValues = NPC.KeyValues,
            }, "cmbevo_" .. shortname)

            if CLIENT then
                language.Add(NPC.Name, NPC.Name)
            end
        end
    end
    NPC = {}
end
LoadNPCS()
hook.Add("OnReloaded", "cmb_evo", LoadNPCS)

-----------------------------------------------------------
-- NPC Initialize Function
-----------------------------------------------------------

if SERVER then

    function CMBEVO.InitializeNPC(ent, shortname)
        if not IsValid(ent) or not ent:IsNPC() then return end
        local data = CMBEVO.NPC[shortname]
        if not data then
            ErrorNoHalt("Tried to initialize invalid CMBEVO NPC \"" .. tostring(shortname) .. "\" on " .. tostring(ent) .. "!\n")
        end

        ent.CMBEVO_ShortName = shortname
        ent:SetKeyValue("parentname", "")

        if data.Tags then
            ent.CMBEVO_Tags = table.Copy(data.Tags)
        end

        if data.Proficiency then
            ent:SetCurrentWeaponProficiency(data.Proficiency)
        end

        if isfunction(data.OnSpawn) then
            data.OnSpawn(ent)
        end

        CMBEVO.NPC_Cache[shortname] = CMBEVO.NPC_Cache[shortname] or {}
        table.insert(CMBEVO.NPC_Cache[shortname], ent)
    end

    hook.Add("OnEntityCreated", "cmb_evo", function(ent)

        if ent:GetClass() == "npc_grenade_frag" then
            timer.Simple(0, function()
                if not IsValid(ent) then return end
                local npc = ent:GetOwner()
                if IsValid(npc) and npc.CMBEVO_ShortName and CMBEVO.NPC[npc.CMBEVO_ShortName] then
                    local final_nade = ent
                    if CMBEVO.NPC[npc.CMBEVO_ShortName].GrenadeEntity then
                        local new_nade = ents.Create(CMBEVO.NPC[npc.CMBEVO_ShortName].GrenadeEntity)
                        new_nade:SetPos(ent:GetPos())
                        new_nade:SetAngles(ent:GetAngles())
                        new_nade:SetOwner(ent:GetOwner())
                        new_nade:SetCollisionGroup(ent:GetCollisionGroup())
                        new_nade:Spawn()
                        new_nade:Activate()
                        new_nade:GetPhysicsObject():SetVelocityInstantaneous(ent:GetPhysicsObject():GetVelocity())
                        new_nade:GetPhysicsObject():SetAngleVelocityInstantaneous(ent:GetPhysicsObject():GetAngleVelocity())
                        ent:Remove()
                        final_nade = new_nade
                    end

                    if isfunction(CMBEVO.NPC[npc.CMBEVO_ShortName].OnGrenadeCreated) then
                        CMBEVO.NPC[npc.CMBEVO_ShortName].OnGrenadeCreated(npc, final_nade)
                    end
                end
                -- PrintTable(ent:GetSaveTable(true))
            end)
        elseif ent:IsNPC() then
            timer.Simple(0, function()
                if not IsValid(ent) then return end
                local name = ent:GetKeyValues()["parentname"] or ""
                if string.Left(name, 7) == "cmbevo_" then
                    CMBEVO.InitializeNPC(ent, string.sub(name, 8))
                end
            end)
        end
    end)

    hook.Add("Think", "cmb_evo", function()
        for shortname, tbl in pairs(CMBEVO.NPC_Cache) do
            if isfunction(CMBEVO.NPC[shortname].Think) then
                for i, npc in pairs(tbl) do
                    if not IsValid(npc) then
                        table.remove(tbl, i)
                        continue
                    end
                    if (npc.CMBEVO_NextThink or 0) < CurTime() then
                        npc.CMBEVO_NextThink = CurTime() + (isnumber(CMBEVO.NPC[shortname].ThinkInterval) and CMBEVO.NPC[shortname].ThinkInterval or 1)
                        CMBEVO.NPC[shortname].Think(npc)
                    end
                end
            end
        end
    end)

    hook.Add("EntityTakeDamage", "cmb_evo_friendly_fire", function(ent, dmginfo)
        if ent.CMBEVO_ShortName ~= nil and ent.CMBEVO_ShortName == dmginfo:GetAttacker().CMBEVO_ShortName and dmginfo:IsBulletDamage() then
            return true
        end
    end)

    hook.Add("OnNPCKilled", "cmb_evo", function(ent, attacker, inflictor)
        if ent.CMBEVO_ShortName and isfunction(CMBEVO.NPC[ent.CMBEVO_ShortName].OnDeath) then
            CMBEVO.NPC[ent.CMBEVO_ShortName].OnDeath(ent, attacker, inflictor)
        end
    end)
end

-----------------------------------------------------------
-- Helper Functions
-----------------------------------------------------------
function CMBEVO.GetTag(ent, tag)
    if not IsValid(ent) or not ent.CMBEVO_Tags then return nil end
    return ent.CMBEVO_Tags[tag]
end

-- https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/sp/src/game/server/h_ai.cpp#L214
function CMBEVO.VecCheckThrow(ent, vecSpot1, vecSpot2, flSpeed, flGravityAdj, vecMins, vecMaxs)
    local flGravity = GetConVar("sv_gravity"):GetFloat() * (flGravityAdj or 1)
    local vecGrenadeVel = vecSpot2 - vecSpot1

    -- throw at a constant time
    local time =  vecGrenadeVel:Length() / flSpeed
    vecGrenadeVel:Mul(1 / time)

    -- adjust upward toss to compensate for gravity loss
    vecGrenadeVel.z = vecGrenadeVel.z + flGravity * time * 0.5

    local vecApex = vecSpot1 + (vecSpot2 - vecSpot1) * 0.5
    vecApex.z = vecApex.z + 0.5 * flGravity * (time * 0.5) * (time * 0.5)

    local tr = util.TraceLine({
        start = vecSpot1,
        endpos = vecApex,
        mask = MASK_SOLID,
        filter = ent,
    })
    if tr.Fraction < 1 then
        return false -- epic fail
    end

    local tr2 = util.TraceLine({
        start = vecSpot2,
        endpos = vecApex,
        mask = MASK_SOLID_BRUSHONLY,
        filter = ent,
    })
    if tr2.Fraction < 1 then
        return false -- epic fail
    end

    if vecMins and vecMaxs then
        local tr3 = util.TraceLine({
            start = vecSpot1,
            endpos = vecApex,
            mask = MASK_SOLID,
            mins = vecMins,
            maxs = vecMaxs,
            filter = ent,
        })
        if tr3.Fraction < 1 then
            return false
        end
    end

    return vecGrenadeVel
end

-- https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/sp/src/game/server/h_ai.cpp#L78
function CMBEVO.VecCheckToss(ent, vecSpot1, vecSpot2, flHeightMaxRatio, flGravityAdj, bRandomize, vecMins, vecMaxs)
    local flGravity = GetConVar("sv_gravity"):GetFloat() * (flGravityAdj or 1)

    if vecSpot2.z - vecSpot1.z > 500 then
        return false -- "to high"
    end

    -- toss a little bit to the left or right, not right down on the enemy's bean (head).
    if bRandomize then
        vecSpot2 = vecSpot2 + ent:GetRight() * math.Rand(-24, 24) + ent:GetForward() * math.Rand(-24, 24)
    end

    -- calculate the midpoint and apex of the 'triangle'
    -- UNDONE: normalize any Z position differences between spot1 and spot2 so that triangle is always RIGHT
    -- get a rough idea of how high it can be thrown
    local vecMidPoint = vecSpot1 + (vecSpot2 - vecSpot1) * 0.5

    local tr0 = util.TraceLine({
        start = vecMidPoint,
        endpos = vecMidPoint + Vector(0, 0, 300),
        mask = MASK_SOLID_BRUSHONLY,
        filter = filter,
    })
    vecMidPoint = tr0.HitPos
    if tr0.Fraction < 1 then
        vecMidPoint.z = vecMidPoint.z - 15
    end
    if flHeightMaxRatio ~= -1 then
        -- But don't throw so high that it looks silly. Maximize the height of the
        -- throw above the highest of the two endpoints to a ratio of the throw length.
    end

    if vecMidPoint.z < vecSpot1.z or vecMidPoint.z < vecSpot2.z then
        return false
    end

    local distance1 = (vecMidPoint.z - vecSpot1.z)
    local distance2 = (vecMidPoint.z - vecSpot2.z)

    local time1 = math.sqrt(distance1 / (0.5 * flGravity))
    local time2 = math.sqrt(distance2 / (0.5 * flGravity))

    if time1 < 0.1 then return false end

    -- how hard to throw sideways to get there in time.
    local vecTossVel = (vecSpot2 - vecSpot1) / (time1 + time2)
    vecTossVel.z = flGravity * time1

    local vecApex = vecSpot1 + vecTossVel * time1
    vecApex.z = vecMidPoint.z

    -- JAY: Repro behavior from HL1 -- toss check went through gratings
    -- well that's stupid so im not doing that
    --[[]
    local tr = util.TraceLine({
        start = vecSpot1,
        endpos = vecApex,
        mask = MASK_SOLID,
        filter = ent,
    })
    if tr.Fraction < 1 then
        return false -- epic fail
    end

    local tr2 = util.TraceLine({
        start = vecSpot2,
        endpos = vecApex,
        mask = MASK_SOLID_BRUSHONLY,
        filter = ent,
    })
    if tr2.Fraction < 1 then
        return false -- epic fail
    end

    if vecMins and vecMaxs then
        local tr3 = util.TraceLine({
            start = vecSpot1,
            endpos = vecApex,
            mask = MASK_SOLID,
            mins = vecMins,
            maxs = vecMaxs,
            filter = ent,
        })
        if tr3.Fraction < 1 then
            return false
        end
    end
    ]]

    return vecTossVel
end