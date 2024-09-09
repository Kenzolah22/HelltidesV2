local utils = require("core.utils")
local enums = require("data.enums")
local explorer = require "core.explorer"
local settings = require "settings"

local task = {
    name = "Repair Items",
    should_execute = function()
        local player = get_local_player()
        
        if not player then
            return false
        end
        
        if check_for_buff(enums.buff_ids.repair_buff) and utils.get_closest_enemy() == nil then
            return true
        end 
    end,
    
    execute = function()
        local current_time = get_time_since_inject()

        if not utils.player_in_zone("Hawe_Bog") and check_for_buff(enums.buff_ids.repair_buff) == true then
            explorer:clear_path_and_target()
            teleport_to_waypoint(enums.towns[1].id)
            return true
        end

        if not settings.has_interacted then
            local blacksmith = utils.get_blacksmith()
            if blacksmith then
                console.print("Setting target to BLACKSMITH: " .. blacksmith:get_skin_name())
                explorer:set_custom_target(blacksmith)
                explorer:move_to_target()

                if utils.distance_to(blacksmith) < 2 then
                    if settings.interact_time == 0 then
                        console.print("Starting interaction timer.")
                        settings.interact_time = current_time
                        return true
                    elseif current_time - settings.interact_time >= 1 and current_time - settings.interact_time < 5 then
                        if current_time - settings.interact_time < 2 then
                            console.print("Player is close enough to the blacksmith. Interacting with the blacksmith.")
                            interact_vendor(blacksmith)
                        end
                        console.print(string.format("Waiting... Time elapsed: %.2f seconds", current_time - settings.interact_time))
                        return true
                    elseif current_time - settings.interact_time >= 5 then
                        console.print("5 seconds have passed. Salvaging items.")
                        loot_manager.interact_with_vendor_and_repair_all(blacksmith)
                        settings.has_interacted = true
                        settings.interact_time = 0
                        settings.reset_interact_time = current_time
                    end
                end
            else
                console.print("No blacksmith found")
                explorer:set_custom_target(enums.npc_positions.blacksmith_position)
                explorer:move_to_target()
            end
        else
            console.print("Returning to portal")
            explorer:set_custom_target(enums.npc_positions.portal_position)
            explorer:move_to_target()

            if enums.npc_positions.portal_position and utils.distance_to(enums.npc_positions.portal_position) < 5 then
                local portal = utils.get_town_portal()
                if portal then
                    if settings.portal_interact_time == 0 then
                        console.print("Starting portal interaction timer.")
                        settings.portal_interact_time = current_time
                        return true
                    elseif current_time - settings.portal_interact_time >= 1 and current_time - settings.portal_interact_time < 5 then
                        if current_time - settings.portal_interact_time < 2 then
                            console.print("Interacting with the portal.")
                            interact_object(portal)
                            settings.has_interactedd = false
                        end
                        console.print(string.format("Waiting at portal... Time elapsed: %.2f seconds", current_time - settings.portal_interact_time))
                        return true
                    elseif current_time - settings.portal_interact_time >= 2 then
                        console.print("2 seconds have passed since portal interaction.")
                        settings.portal_interact_time = 0
                        console.print(string.format("Time passed since interaction: %.2f seconds", current_time - settings.reset_interact_time))
                    end
                else
                    console.print("Town portal not found")
                end
            end
        end

        return true
    end,
    
    on_enter = function()
        -- Any setup logic for entering repair mode can go here
    end,

    on_exit = function()
        -- Any cleanup logic for exiting repair mode can go here
    end
}

return task