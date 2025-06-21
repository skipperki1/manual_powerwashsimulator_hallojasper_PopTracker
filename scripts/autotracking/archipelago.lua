-- this is an example/default implementation for AP autotracking
-- it will use the mappings defined in item_mapping.lua and location_mapping.lua to track items and locations via their ids
-- it will also keep track of the current index of on_item messages in CUR_INDEX
-- addition it will keep track of what items are local items and which one are remote using the globals LOCAL_ITEMS and GLOBAL_ITEMS
-- this is useful since remote items will not reset but local items might
-- if you run into issues when touching A LOT of items/locations here, see the comment about Tracker.AllowDeferredLogicUpdate in autotracking.lua
ScriptHost:LoadScript("scripts/autotracking/item_mapping.lua")
ScriptHost:LoadScript("scripts/autotracking/location_mapping.lua")
ScriptHost:LoadScript("scripts/autotracking/sectionID.lua")

CUR_INDEX = -1
LOCAL_ITEMS = {}
GLOBAL_ITEMS = {}

-- resets an item to its initial state
function resetItem(item_code, item_type)
	local obj = Tracker:FindObjectForCode(item_code)
	if ARTSANITY then
		if obj then
			item_type = item_type or obj.Type
			if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
				print(string.format("resetItem: resetting item %s of type %s", item_code, item_type))
			end
			if item_type == "toggle" or item_type == "toggle_badged" then
				obj.Active = false
			elseif item_type == "progressive" or item_type == "progressive_toggle" then
				obj.CurrentStage = 0
				obj.Active = false
			elseif obj.AcquiredCount == 1 then
				print("Total set to 1 for: ",item_code)
				obj.AcquiredCount = 1
			elseif item_type == "consumable" and obj.AcquiredCount ~= 1 then
				print("Total set to 0 for: ",item_code)
				obj.AcquiredCount = 0
			elseif item_type == "custom" then
				-- your code for your custom lua items goes here
			elseif item_type == "static" and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
				print(string.format("resetItem: tried to reset static item %s", item_code))
			elseif item_type == "composite_toggle" and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
				print(string.format(
					"resetItem: tried to reset composite_toggle item %s but composite_toggle cannot be accessed via lua." ..
					"Please use the respective left/right toggle item codes instead.", item_code))
			elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
				print(string.format("resetItem: unknown item type %s for code %s", item_type, item_code))
			end
		elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("resetItem: could not find item object for code %s", item_code))
		end
	else
		if obj then
			item_type = item_type or obj.Type
			if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
				print(string.format("resetItem: resetting item %s of type %s", item_code, item_type))
			end
			if item_type == "toggle" or item_type == "toggle_badged" then
				obj.Active = false
			elseif item_type == "progressive" or item_type == "progressive_toggle" then
				obj.CurrentStage = 0
				obj.Active = false
			elseif obj.AcquiredCount == 4 then
				print("Total set to 4 for: ",item_code)
				obj.AcquiredCount = 4
			elseif item_type == "consumable" and obj.AcquiredCount ~= 4 then
				print("Total set to 0 for: ",item_code)
				obj.AcquiredCount = 0
			elseif item_type == "custom" then
				-- your code for your custom lua items goes here
			elseif item_type == "static" and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
				print(string.format("resetItem: tried to reset static item %s", item_code))
			elseif item_type == "composite_toggle" and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
				print(string.format(
					"resetItem: tried to reset composite_toggle item %s but composite_toggle cannot be accessed via lua." ..
					"Please use the respective left/right toggle item codes instead.", item_code))
			elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
				print(string.format("resetItem: unknown item type %s for code %s", item_type, item_code))
			end
		elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("resetItem: could not find item object for code %s", item_code))
		end
	end
end

-- advances the state of an item
function incrementItem(item_code, item_type, multiplier)
	local obj = Tracker:FindObjectForCode(item_code)
	if obj then
		item_type = item_type or obj.Type
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("incrementItem: code: %s, type %s", item_code, item_type))
		end
		if item_type == "toggle" or item_type == "toggle_badged" then
			obj.Active = true
		elseif item_type == "progressive" or item_type == "progressive_toggle" then
			if obj.Active then
				obj.CurrentStage = obj.CurrentStage + 1
			else
				obj.Active = true
			end
		elseif item_type == "consumable" then
			obj.AcquiredCount = obj.AcquiredCount + obj.Increment * multiplier
		elseif item_type == "custom" then
			-- your code for your custom lua items goes here
		elseif item_type == "static" and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("incrementItem: tried to increment static item %s", item_code))
		elseif item_type == "composite_toggle" and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format(
				"incrementItem: tried to increment composite_toggle item %s but composite_toggle cannot be access via lua." ..
				"Please use the respective left/right toggle item codes instead.", item_code))
		elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("incrementItem: unknown item type %s for code %s", item_type, item_code))
		end
	elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("incrementItem: could not find object for code %s", item_code))
	end
end

-- apply everything needed from slot_data, called from onClear
function apply_slot_data(slot_data)
	-- put any code here that slot_data should affect (toggling setting items for example)
end

-- called right after an AP slot is connected
function onClear(slot_data)
	-- use bulk update to pause logic updates until we are done resetting all items/locations
	Tracker.BulkUpdate = true	
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("called onClear, slot_data:\n%s", dump_table(slot_data)))
	end
	CUR_INDEX = -1
	SLOT_DATA = slot_data
	-- reset locations
	for _, mapping_entry in pairs(LOCATION_MAPPING) do
		for _, location_table in ipairs(mapping_entry) do
			if location_table then
				local location_code = location_table[1]
				if location_code then
					if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
						print(string.format("onClear: clearing location %s", location_code))
					end
					if location_code:sub(1, 1) == "@" then
						local obj = Tracker:FindObjectForCode(location_code)
						if obj then
							obj.AvailableChestCount = obj.ChestCount
						elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
							print(string.format("onClear: could not find location object for code %s", location_code))
						end
					else
						-- reset hosted item
						local item_type = location_table[2]
						resetItem(location_code, item_type)
					end
				elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
					print(string.format("onClear: skipping location_table with no location_code"))
				end
			elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
				print(string.format("onClear: skipping empty location_table"))
			end
		end
	end
	-- reset items
	for _, mapping_entry in pairs(ITEM_MAPPING) do
		for _, item_table in ipairs(mapping_entry) do
			if item_table then
				local item_code = item_table[1]
				local item_type = item_table[2]
				if item_code then
					resetItem(item_code, item_type)
				elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
					print(string.format("onClear: skipping item_table with no item_code"))
				end
			elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
				print(string.format("onClear: skipping empty item_table"))
			end
		end
	end
	
	apply_slot_data(slot_data)
	LOCAL_ITEMS = {}
	GLOBAL_ITEMS = {}

	for k, v in pairs(SETTINGS_MAPPING) do
		obj = Tracker:FindObjectForCode(v)

		local value = SLOT_DATA[k]
		local tog = value == 1

		if k == "Parts_Mode" then
			Tracker:FindObjectForCode("mode").CurrentStage = value
		elseif k == "Include_Temple" then
			Tracker:FindObjectForCode("YesTemple").Active = tog

		elseif k == "Hard_Parkour" then
			Tracker:FindObjectForCode("HardParkour").Active = tog

		elseif k == "Include_Forest_Cottage" then
			Tracker:FindObjectForCode("YesForestCottage").Active = tog

		elseif k == "Include_Fortune_Tellers_Wagon" then
			Tracker:FindObjectForCode("YesFortuneTellersWagon").Active = tog

		elseif k == "Include_Fire_Truck" then
			Tracker:FindObjectForCode("YesFireTruck").Active = tog

		elseif k == "Include_Shoe_House" then
			Tracker:FindObjectForCode("YesShoeHouse").Active = tog

		elseif k == "Include_Grandpa_Millers_Car" then
			Tracker:FindObjectForCode("YesGrandpaMillersCar").Active = tog

		elseif k == "Include_Private_Jet" then
			Tracker:FindObjectForCode("YesPrivateJet").Active = tog

		elseif k == "Include_Ancient_Statue" then
			Tracker:FindObjectForCode("YesAncientStatue").Active = tog

		elseif k == "Include_Skatepark" then
			Tracker:FindObjectForCode("YesSkatepark").Active = tog

		elseif k == "Include_Back_Garden" then
			Tracker:FindObjectForCode("YesBackGarden").Active = tog

		elseif k == "Include_Ferris_Wheel" then
			Tracker:FindObjectForCode("YesFerrisWheel").Active = tog

		elseif k == "Include_Tree_House" then
			Tracker:FindObjectForCode("YesTreeHouse").Active = tog

		elseif k == "Include_Bungalow" then
			Tracker:FindObjectForCode("YesBungalow").Active = tog

		elseif k == "Include_Drill" then
			Tracker:FindObjectForCode("YesDrill").Active = tog

		elseif k == "Include_Vintage_Car" then
			Tracker:FindObjectForCode("YesVintageCar").Active = tog

		elseif k == "Include_Fire_Helicopter" then
			Tracker:FindObjectForCode("YesFireHelicopter").Active = tog

		elseif k == "Include_Washroom" then
			Tracker:FindObjectForCode("YesWashroom").Active = tog

		elseif k == "Include_Subway_Platform" then
			Tracker:FindObjectForCode("YesSubwayPlatform").Active = tog

		elseif k == "Include_Van" then
			Tracker:FindObjectForCode("YesVan").Active = tog

		elseif k == "Include_Golf_Cart" then
			Tracker:FindObjectForCode("YesGolfCart").Active = tog

		elseif k == "Include_Fishing_Boat" then
			Tracker:FindObjectForCode("YesFishingBoat").Active = tog

		elseif k == "Include_SUV" then
			Tracker:FindObjectForCode("YesSUV").Active = tog

		elseif k == "Include_Recreation_Vehicle" then
			Tracker:FindObjectForCode("YesRecreationVehicle").Active = tog

		elseif k == "Include_Frolic_Boat" then
			Tracker:FindObjectForCode("YesFrolicBoat").Active = tog

		elseif k == "Include_Mayors_Mansion" then
			Tracker:FindObjectForCode("YesMayorsMansion").Active = tog

		elseif k == "Include_Stunt_Plane" then
			Tracker:FindObjectForCode("YesStuntPlane").Active = tog

		elseif k == "Include_Penny_Farthing" then
			Tracker:FindObjectForCode("YesPennyFarthing").Active = tog

		elseif k == "Include_Playground" then
			Tracker:FindObjectForCode("YesPlayground").Active = tog

		elseif k == "Include_Monster_Truck" then
			Tracker:FindObjectForCode("YesMonsterTruck").Active = tog

		elseif k == "Include_Lost_City_Palace" then
			Tracker:FindObjectForCode("YesLostCityPalace").Active = tog

		elseif k == "Include_Detached_House" then
			Tracker:FindObjectForCode("YesDetachedHouse").Active = tog

		elseif k == "Include_Ancient_Monument" then
			Tracker:FindObjectForCode("YesAncientMonument").Active = tog

		elseif k == "Include_Recreational_Vehicle_Again" then
			Tracker:FindObjectForCode("YesRecreationVehicleAgain").Active = tog

		elseif k == "Include_Motorbike_and_Sidecar" then
			Tracker:FindObjectForCode("YesMotorbikeandSidecar").Active = tog

		elseif k == "Include_Dirt_Bike" then
			Tracker:FindObjectForCode("YesDirtBike").Active = tog
		end
		
	end

	-- manually run snes interface functions after onClear in case we need to update them (i.e. because they need slot_data)
	if PopVersion < "0.20.1" or AutoTracker:GetConnectionState("SNES") == 3 then
		-- add snes interface functions here
	end
	Tracker.BulkUpdate = false
end

-- called when an item gets collected
function onItem(index, item_id, item_name, player_number)
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("called onItem: %s, %s, %s, %s, %s", index, item_id, item_name, player_number, CUR_INDEX))
	end
	if not AUTOTRACKER_ENABLE_ITEM_TRACKING then
		return
	end
	if index <= CUR_INDEX then
		return
	end
	local is_local = player_number == Archipelago.PlayerNumber
	CUR_INDEX = index;
	local mapping_entry = ITEM_MAPPING[item_id]
	if not mapping_entry then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("onItem: could not find item mapping for id %s", item_id))
		end
		return
	end
	for _, item_table in pairs(mapping_entry) do
		if item_table then
			local item_code = item_table[1]
			local item_type = item_table[2]
			local multiplier = item_table[3] or 1
			if item_code then
				incrementItem(item_code, item_type, multiplier)
				-- keep track which items we touch are local and which are global
				if is_local then
					if LOCAL_ITEMS[item_code] then
						LOCAL_ITEMS[item_code] = LOCAL_ITEMS[item_code] + 1
					else
						LOCAL_ITEMS[item_code] = 1
					end
				else
					if GLOBAL_ITEMS[item_code] then
						GLOBAL_ITEMS[item_code] = GLOBAL_ITEMS[item_code] + 1
					else
						GLOBAL_ITEMS[item_code] = 1
					end
				end
			elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
				print(string.format("onClear: skipping item_table with no item_code"))
			end
		elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("onClear: skipping empty item_table"))
		end
	end
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("local items: %s", dump_table(LOCAL_ITEMS)))
		print(string.format("global items: %s", dump_table(GLOBAL_ITEMS)))
	end
	-- track local items via snes interface
	if PopVersion < "0.20.1" or AutoTracker:GetConnectionState("SNES") == 3 then
		-- add snes interface functions for local item tracking here
	end
end

-- called when a location gets cleared
function onLocation(location_id, location_name)
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("called onLocation: %s, %s", location_id, location_name))
	end
	if not AUTOTRACKER_ENABLE_LOCATION_TRACKING then
		return
	end
	local mapping_entry = LOCATION_MAPPING[location_id]
	if not mapping_entry then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("onLocation: could not find location mapping for id %s", location_id))
		end
		return
	end
	for _, location_table in pairs(mapping_entry) do
		if location_table then
			local location_code = location_table[1]
			if location_code then
				local obj = Tracker:FindObjectForCode(location_code)
				if obj then
					if location_code:sub(1, 1) == "@" then
						obj.AvailableChestCount = obj.AvailableChestCount - 1
					else
						-- increment hosted item
						local item_type = location_table[2]
						incrementItem(location_code, item_type)
					end
				elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
					print(string.format("onLocation: could not find object for code %s", location_code))
				end
			elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
				print(string.format("onLocation: skipping location_table with no location_code"))
			end
		elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("onLocation: skipping empty location_table"))
		end
	end
end

ScriptHost:AddOnLocationSectionChangedHandler("manual", function(section)
    local sectionID = section.FullID
    if sectionID == "Victory/Victory/Victory" then
        if section.AvailableChestCount == 0 then
            local res = Archipelago:StatusUpdate(Archipelago.ClientStatus.GOAL)
            if res then
                print("Sent Victory")
                local obj = Tracker:FindObjectForCode("event_cynthia")
                obj.Active = true
            else
                print("Error sending Victory")
            end
        end
    elseif (section.AvailableChestCount == 0) then  -- this only works for 1 chest per section
        -- AP location cleared
        local sectionID = section.FullID
        local apID = sectionIDToAPID[sectionID]
        if apID ~= nil then
            local res = Archipelago:LocationChecks({apID})
            if res then
                print("Sent " .. tostring(apID) .. " for " .. tostring(sectionID))
            else
                print("Error sending " .. tostring(apID) .. " for " .. tostring(sectionID))
            end
        else
            print(tostring(sectionID) .. " is not an AP location")
        end
    end
end)

-- called when a locations is scouted
function onScout(location_id, location_name, item_id, item_name, item_player)
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("called onScout: %s, %s, %s, %s, %s", location_id, location_name, item_id, item_name,
			item_player))
	end
	-- not implemented yet :(
end

-- called when a bounce message is received
function onBounce(json)
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("called onBounce: %s", dump_table(json)))
	end
	-- your code goes here
end

-- add AP callbacks
-- un-/comment as needed
Archipelago:AddClearHandler("clear handler", onClear)
if AUTOTRACKER_ENABLE_ITEM_TRACKING then
	Archipelago:AddItemHandler("item handler", onItem)
end
if AUTOTRACKER_ENABLE_LOCATION_TRACKING then
	Archipelago:AddLocationHandler("location handler", onLocation)
end
-- Archipelago:AddScoutHandler("scout handler", onScout)
-- Archipelago:AddBouncedHandler("bounce handler", onBounce)

function trigger3000()
	Tracker:FindObjectForCode("PV3000").Active = Tracker:FindObjectForCode("PV3000Nozzles").CurrentStage ~= 0
end

function triggerUrban()
	Tracker:FindObjectForCode("UrbanXU2").Active = Tracker:FindObjectForCode("UrbanXU2Nozzles").CurrentStage ~= 0
end

function triggerPro()
	Tracker:FindObjectForCode("PVPro").Active = Tracker:FindObjectForCode("PVProNozzles").CurrentStage ~= 0
end

ScriptHost:AddWatchForCode("Toggle PV3000","PV3000Nozzles",trigger3000)
ScriptHost:AddWatchForCode("Toggle UrbanXU2","UrbanXU2Nozzles",triggerUrban)
ScriptHost:AddWatchForCode("Toggle PVPro","PVProNozzles",triggerPro)

function triggerSurface()
	Tracker:FindObjectForCode("Surface").Active = Tracker:FindObjectForCode("PV1500Nozzles").CurrentStage ~= 0
end

function triggerEncrusted()
	Tracker:FindObjectForCode("Encrusted").Active = (Tracker:FindObjectForCode("PV1500Nozzles").CurrentStage >= 2 or Tracker:FindObjectForCode("UrbanXU2Nozzles").CurrentStage ~= 0 or Tracker:FindObjectForCode("PV3000Nozzles").CurrentStage ~= 0 or Tracker:FindObjectForCode("PVProNozzles").CurrentStage ~= 0) 
end

function triggerEmbedded()
	Tracker:FindObjectForCode("Embedded").Active = (Tracker:FindObjectForCode("PV1500Nozzles").CurrentStage >= 3 or Tracker:FindObjectForCode("UrbanXU2Nozzles").CurrentStage >= 2 or Tracker:FindObjectForCode("PV3000Nozzles").CurrentStage ~= 0 or Tracker:FindObjectForCode("PVProNozzles").CurrentStage ~= 0) 
end

function triggerTough()
	Tracker:FindObjectForCode("Tough").Active = (Tracker:FindObjectForCode("PV1500Nozzles").CurrentStage == 4 or Tracker:FindObjectForCode("UrbanXU2Nozzles").CurrentStage >= 3 or Tracker:FindObjectForCode("PV3000Nozzles").CurrentStage >= 2 or Tracker:FindObjectForCode("PVProNozzles").CurrentStage ~= 0) 
end

function triggerStubborn()
	Tracker:FindObjectForCode("Stubborn").Active = (Tracker:FindObjectForCode("UrbanXU2Nozzles").CurrentStage >= 3 or Tracker:FindObjectForCode("PV3000Nozzles").CurrentStage >= 2 or Tracker:FindObjectForCode("PVProNozzles").CurrentStage ~= 0) 
end

function triggerIngrained()
	Tracker:FindObjectForCode("Ingrained").Active = (Tracker:FindObjectForCode("PV3000Nozzles").CurrentStage >= 4 or Tracker:FindObjectForCode("PVProNozzles").CurrentStage >= 2)
end

function triggerOily()
	Tracker:FindObjectForCode("Oily").Active = Tracker:FindObjectForCode("PVProNozzles").CurrentStage >= 4
end

ScriptHost:AddWatchForCode("Toggle Surface Region","Nozzles",triggerSurface)
ScriptHost:AddWatchForCode("Toggle Encrusted Region","Nozzles",triggerEncrusted)
ScriptHost:AddWatchForCode("Toggle Embedded Region","Nozzles",triggerEmbedded)
ScriptHost:AddWatchForCode("Toggle Tough Region","Nozzles",triggerTough)
ScriptHost:AddWatchForCode("Toggle Stubborn Region","Nozzles",triggerStubborn)
ScriptHost:AddWatchForCode("Toggle Ingrained Region","Nozzles",triggerIngrained)
ScriptHost:AddWatchForCode("Toggle Oily Region","Nozzles",triggerOily)