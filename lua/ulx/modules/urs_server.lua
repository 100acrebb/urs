AddCSLuaFile( "ulx/modules/sh/urs_cmds.lua" )

if !URS then URS = {} end 

HOOK_LOW = HOOK_LOW or 1 -- ensure we don't break on old versions of ULib
local MY_HOOK_LOW = -10

function URS.Load() 
	URS.restrictions = {} 
	URS.limits = {}
	URS.loadouts = {} 


	if file.Exists( "ulx/restrictions.txt", "DATA" ) then URS.restrictions = util.JSONToTable( file.Read( "ulx/restrictions.txt", "DATA" ) ) end
	if file.Exists( "ulx/limits.txt", "DATA" ) then URS.limits = util.JSONToTable( file.Read( "ulx/limits.txt", "DATA" ) ) end
	if file.Exists( "ulx/loadouts.txt", "DATA" ) then URS.loadouts = util.JSONToTable( file.Read( "ulx/loadouts.txt", "DATA" ) ) end

	-- Initiallize all tables to prevent errors
	for type, types in pairs(URS.types) do 
		if !URS[type] then 
			URS[type] = {} 
		end 

		for k, v in pairs(types) do 
			if !URS[type][v] then 
				URS[type][v] = {} 
			end 
		end 
	end 
end

URS_SAVE_ALL = 0
URS_SAVE_RESTRICIONS = 1 
URS_SAVE_LIMITS = 2 
URS_SAVE_LOADOUTS = 3

function URS.Save(n)
	if (n == URS_SAVE_ALL or n == URS_SAVE_RESTRICTIONS) 	and URS.restrictions then file.Write("ulx/restrictions.txt", util.TableToJSON(URS.restrictions)) end
	if (n == URS_SAVE_ALL or n == URS_SAVE_LIMITS) 			and URS.limits then file.Write("ulx/limits.txt", util.TableToJSON(URS.limits)) end
	if (n == URS_SAVE_ALL or n == URS_SAVE_LOADOUTS) 		and URS.loadouts then file.Write("ulx/loadouts.txt", util.TableToJSON(URS.loadouts)) end
end

function URS.PrintRestricted(ply, type, what) 
	if type == "pickup" then return end -- Constant spam
	if URS.cfg.echoSpawns:GetBool() then 
		ulx.logSpawn(ply:Nick() .."<".. ply:SteamID() .."> spawned/used ".. type .." ".. what .." -=RESTRICTED=-")
	end 
	ULib.tsayError(ply, "\"".. what .."\" is a restricted ".. type .." from your rank. Say !rank for more info.")
end 

function URS.Check(ply, type, what, noecho, ... )

	-- MTZ
	--print ("URS.Check", ply:Name(), type, what)
	if ply:IsSuperAdmin() then return end
	
	what = string.lower(what) 
	local group = ply:GetUserGroup() 
	local restriction = false
	
	-- if we passed a description, use that for messages instead   MTZ
	local whatdesc = what
	local arg={...}
	if arg[1] != nil then
		whatdesc = arg[1]
	end
	local passedRestrictionTest = false
	

	if URS.restrictions[type] and URS.restrictions[type][what] then 
		restriction = URS.restrictions[type][what] 
	end 

	if restriction then 
		if table.HasValue(restriction, "*") then 
			if !(table.HasValue(restriction, group) or table.HasValue(restriction, ply:SteamID())) then 
				if !noecho then URS.PrintRestricted(ply, type, whatdesc) end
				return false
			end 
		elseif table.HasValue(restriction, group) or table.HasValue(restriction, ply:SteamID()) then 
			if !noecho then URS.PrintRestricted(ply, type, whatdesc) end
			return false 
		end
		passedRestrictionTest = true -- we overtly passed the restriction test.  Don't bother looking at wildcards later on  MTZ
		--print("overt restriction passage detected")
		--PrintTable(restriction)
	end 
	
	if URS.restrictions["all"] and URS.restrictions["all"][type] and table.HasValue(URS.restrictions["all"][type], group) then 
		if !noecho then ULib.tsayError(ply, "Your rank is restricted from all ".. type .."s") end
		return false 
	end
	
	if table.HasValue(URS.types.limits, type) and URS.limits[type] and (URS.limits[type][ply:SteamID()] or URS.limits[type][group]) then 
		if URS.limits[type][ply:SteamID()] then 
			if ply:GetCount(type.."s") >= URS.limits[type][ply:SteamID()] then 
				ply:LimitHit( type .."s" )
				return false 
			end 
		elseif URS.limits[type][group] then 
			if ply:GetCount(type.."s") >= URS.limits[type][group] then 
				ply:LimitHit( type .."s" )
				return false 
			end 
		end 
	--	if URS.cfg.overwriteSbox:GetBool() then 
	--		return true -- Overwrite sbox limit (ours is greater) 
	--	end  -- mtz
	end



	-- find wildcard entires and recurse against it   MTZ
	if !string.ends(what,"*") and passedRestrictionTest == false then
		local whatwild = converttowildcard(what)
		if whatwild != what and whatwild != "" then
			local res = URS.Check( ply, type, whatwild, noecho, what )
			if (res == false) then
				return false
			end
		end
	end


	
end

-- MTZ
function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end
function string.ends(String,End)
   return End=='' or string.sub(String,-string.len(End))==End
end

function converttowildcard(what)
	local what2 = ""
	
	if string.starts(what, "weapon_doom3_") then what2 = "weapon_doom3_*"
	elseif string.starts(what, "npcg_") then what2 = "npcg_*"
	elseif string.starts(what, "gb5_light_") then what2 = "gb5_light_*"
	elseif string.starts(what, "gb5_") then what2 = "gb5_*"
	elseif string.starts(what, "halo_swep_") then what2 = "halo_swep_*"
	elseif string.starts(what, "weapon_sky_") then what2 = "weapon_sky_*"
	elseif string.starts(what, "m9k_") then what2 = "m9k_*"
	elseif string.starts(what, "crysis_wep_") then what2 = "crysis_wep_*"
	elseif string.starts(what, "weapon_752_") then what2 = "weapon_752_*"
	elseif string.starts(what, "fas2_") then what2 = "fas2_*"
	end
	
	return what2
end
-- END MTZ






timer.Simple(0.1, function() 

	--  Wiremod's Advanced Duplicator
	if AdvDupe then 
	
	   -- print ("Setting up AdvDupe check...")
		AdvDupe.AdminSettings.AddEntCheckHook( "URSDupeCheck", 
		function(ply, Ent, EntTable) 
		--	print ("Checking AdvDupe")
			return URS.Check( ply, "advdupe", EntTable.Class )
		end, 
		function(Hook) 
			ULib.tsayColor( nil, false, Color( 255, 0, 0 ), "URSDupeCheck has failed.  Please contact Aaron113 @\nhttp://forums.ulyssesmod.net/index.php/topic,5269.0.html" )
		end )
	end

	-- Advanced Duplicator 2 (http://facepunch.com/showthread.php?t=1136597)
	if AdvDupe2 then 
		--print ("Setting up AdvDupe2 check...")
		hook.Add("PlayerSpawnEntity", "URSCheckRestrictedEntity", function(ply, EntTable) 
		--	print ("Checking AdvDupe2")
			--if URS.Check(ply, "advdupe", EntTable.Class) == false or URS.Check(ply, "advdupe", EntTable.Model) == false then 
			if URS.Check(ply, "sent", EntTable.Class) == false or URS.Check(ply, "prop", EntTable.Model) == false then 
				return false 
			end 
		end) 
	end 

end )

function URS.CheckRestrictedSENT(ply, sent)
	return URS.Check( ply, "sent", sent )
end
hook.Add( "PlayerSpawnSENT", "URSCheckRestrictedSENT", URS.CheckRestrictedSENT, MY_HOOK_LOW )

function URS.CheckRestrictedProp(ply, mdl)
	return URS.Check( ply, "prop", mdl )
end
hook.Add( "PlayerSpawnProp", "URSCheckRestrictedProp", URS.CheckRestrictedProp, MY_HOOK_LOW )

function URS.CheckRestrictedTool(ply, tr, tool)
	if URS.Check( ply, "tool", tool ) == false then return false end
	if URS.cfg.echoSpawns:GetBool() and tool != "inflator" then
		ulx.logSpawn( ply:Nick().."<".. ply:SteamID() .."> used the tool ".. tool .." on ".. tr.Entity:GetModel() )
	end
end
hook.Add( "CanTool", "URSCheckRestrictedTool", URS.CheckRestrictedTool, MY_HOOK_LOW )

function URS.CheckRestrictedEffect(ply, mdl)
	return URS.Check( ply, "effect", mdl )
end
hook.Add( "PlayerSpawnEffect", "URSCheckRestrictedEffect", URS.CheckRestrictedEffect, MY_HOOK_LOW )

function URS.CheckRestrictedNPC(ply, npc, weapon)
	return URS.Check( ply, "npc", npc )
end
hook.Add( "PlayerSpawnNPC", "URSCheckRestrictedNPC", URS.CheckRestrictedNPC, MY_HOOK_LOW )

function URS.CheckRestrictedRagdoll(ply, mdl)
	return URS.Check( ply, "ragdoll", mdl )
end
hook.Add( "PlayerSpawnRagdoll", "URSCheckRestrictedRagdoll", URS.CheckRestrictedRagdoll, MY_HOOK_LOW )

function URS.CheckRestrictedSWEP(ply, class, weapon)
	if URS.Check( ply, "swep", class ) == false then 
		return false 
	elseif URS.cfg.echoSpawns:GetBool() then 
		ulx.logSpawn( ply:Nick().."<".. ply:SteamID() .."> spawned/gave himself swep ".. class ) 
	end 
end
hook.Add( "PlayerSpawnSWEP", "URSCheckRestrictedSWEP", URS.CheckRestrictedSWEP, MY_HOOK_LOW )
hook.Add( "PlayerGiveSWEP", "URSCheckRestrictedSWEP2", URS.CheckRestrictedSWEP, MY_HOOK_LOW )

function URS.CheckRestrictedPickUp(ply, weapon)
	if URS.cfg.weaponPickups:GetInt() == 2 then
		if URS.Check( ply, "pickup", weapon:GetClass(), true) == false then 
			return false 
		end 
	elseif URS.cfg.weaponPickups:GetInt() == 1 then
		if URS.Check( ply, "swep", weapon:GetClass(), true) == false then 
			return false 
		end 
	end
end
hook.Add( "PlayerCanPickupWeapon", "URSCheckRestrictedPickUp", URS.CheckRestrictedPickUp, MY_HOOK_LOW )

function URS.CheckRestrictedVehicle(ply, mdl, name, vehicle_table)
	return URS.Check( ply, "vehicle", mdl ) and URS.Check( ply, "vehicle", name )
end
hook.Add( "PlayerSpawnVehicle", "URSCheckRestrictedVehicle", URS.CheckRestrictedVehicle, MY_HOOK_LOW )

function URS.CustomLoadouts(ply)
	if URS.loadouts[ply:SteamID()] then
		ply:StripWeapons()
		for k, v in pairs( URS.loadouts[ply:SteamID()] ) do
			ply:Give( v )
		end
		return true
	elseif URS.loadouts[ply:GetUserGroup()] then
		ply:StripWeapons()
		for k, v in pairs( URS.loadouts[ply:GetUserGroup()] ) do
			ply:Give( v )
		end
		return true
	end
end
hook.Add( "PlayerLoadout", "URSCustomLoadouts", URS.CustomLoadouts, MY_HOOK_LOW )