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
            Weapons = NPC.Weapons,
            SpawnFlags = NPC.SpawnFlags,
            KeyValues = NPC.KeyValues,
        }, "cmbevo_" .. shortname)
    end
end

if SERVER then
    hook.Add("OnEntityCreated", "cmb_evo", function(ent)

        if ent:GetClass() == "npc_grenade_frag" then
            timer.Simple(0, function()
                local npc = ent:GetOwner()
                if npc.CMBEVO_ShortName and CMBEVO.NPC[npc.CMBEVO_ShortName] then
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
        end
    end)

    hook.Add("PlayerSpawnedNPC", "cmb_evo", function(ply, ent)
        local name = ent:GetKeyValues()["parentname"] or ""

        if string.Left(name, 7) == "cmbevo_" then
            local shortname = string.sub(name, 8)
            if CMBEVO.NPC[shortname] then
                ent.CMBEVO_ShortName = shortname
                ent:SetKeyValue("parentname", "")

                if CMBEVO.NPC[shortname].Tags then
                    ent.CMBEVO_Tags = table.Copy(CMBEVO.NPC[shortname].Tags)
                end

                if isfunction(CMBEVO.NPC[shortname].OnSpawn) then
                    CMBEVO.NPC[shortname].OnSpawn(ent, ply)
                end

                CMBEVO.NPC_Cache[shortname] = CMBEVO.NPC_Cache[shortname] or {}
                table.insert(CMBEVO.NPC_Cache[shortname], ent)
            end
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
                    CMBEVO.NPC[shortname].Think(npc)
                end
            end
        end
    end)

    hook.Add("EntityTakeDamage", "cmb_evo_friendly_fire", function(ent, dmginfo)
        if ent.CMBEVO_ShortName ~= nil and ent.CMBEVO_ShortName == dmginfo:GetAttacker().CMBEVO_ShortName and dmginfo:IsBulletDamage() then
            return true
        end
    end)
end

-----------------------------------------------------------
-- Helper Functions
-----------------------------------------------------------
function CMBEVO.GetTag(ent, tag)
    if not ent.CMBEVO_Tags then return nil end
    return ent.CMBEVO_Tags[tag]
end