gdebug.log_info("Washing: main.")

--[[
    Main script.
    This file can be loaded multiple times (e.g. when you press a key to
    hot-reload Lua code), so ideally we shouldn't modify here any state defined
    in earlier load stages.
]]
--

local mod = game.mod_runtime[game.current_mod]
local wash_flag_id = JsonFlagId.new( "WASHED" )
local fragile_flag_id = JsonFlagId.new( "FRAGILE" )
local washes_soft_flag_id = JsonFlagId.new( "WASHES_SOFT" )
local washes_fragile_flag_id = JsonFlagId.new( "WASHES_FRAGILE" )
local washes_hard_flag_id = JsonFlagId.new( "WASHES_HARD" )
local mood_effect_id = EffectTypeId.new( "washed_clothes" )

mod.wash_item = function (item)
    item:set_flag(wash_flag_id)
    gapi.add_msg(locale.gettext("You wash the ") .. item:display_name(1) .. locale.gettext(".") )
    item:set_var_str("item_label", "<color_white>" .. item:tname(1, false, 0) .. locale.gettext(" (washed)") .. "</color>")
end

mod.sully_item = function (item)
    item:remove_flag(wash_flag_id)
    item:erase_var("item_label")
    gapi.add_msg(locale.gettext("Your ") .. item:display_name(1) .. locale.gettext(" has been sullied!") )
end

mod.is_worn_by_player = function(item)
    local who = gapi.get_avatar():as_character()
    if not who then return false end -- Ensure player exists
    return who:is_worn(item) and item:is_armor()
end

mod.iuse_wash_action = function( who, item, pos )
    local all_items = who:all_items(true)
    local soft_washable_items = {}
    local fragile_washable_items = {}
    local hard_washable_items = {}

    for _, item_to_check in ipairs(all_items) do
        if not item_to_check:is_armor() or item_to_check:has_flag( wash_flag_id ) then
            goto continue_loop_initial_filter
        end
        if item_to_check:is_soft() then
            table.insert( soft_washable_items, item_to_check )
        elseif item_to_check:has_flag( fragile_flag_id ) then
            table.insert( fragile_washable_items, item_to_check )
        else
            table.insert( hard_washable_items, item_to_check )
        end
        ::continue_loop_initial_filter::
    end

    -- This table will store the actual item objects that are selected.
    -- Using it as a set for quick add/remove/check. Key = item_obj, Value = true
    local selected_item_object_set = {}

    while true do
        local ui = UiList.new()
        ui:title(locale.gettext("Select items to wash (toggle selection, Esc to cancel)"))
        
        -- This map is rebuilt each time the UI is displayed.
        -- It maps the current UI's 1-based index (eidx) to the item object.
        local current_loop_ui_key_to_item_map = {}
        local current_ui_key = 1

        local function add_item_category_to_ui(items_list_for_category)
            for _, item_obj_to_display in ipairs(items_list_for_category) do
                local display_text = item_obj_to_display:display_name(1)
                if selected_item_object_set[item_obj_to_display] then
                    display_text = "    " .. display_text
                end
                ui:add(current_ui_key, display_text)
                current_loop_ui_key_to_item_map[current_ui_key] = item_obj_to_display
                current_ui_key = current_ui_key + 1
            end
        end

        if item:has_flag( washes_soft_flag_id ) then
            add_item_category_to_ui(soft_washable_items)
        end
        if item:has_flag( washes_fragile_flag_id ) then
            add_item_category_to_ui(fragile_washable_items)
        end
        if item:has_flag( washes_hard_flag_id ) then
            add_item_category_to_ui(hard_washable_items)
        end

        local total_items_for_this_machine_type = current_ui_key - 1

        if total_items_for_this_machine_type == 0 then
            local any_washable_items_at_all = #soft_washable_items > 0 or #fragile_washable_items > 0 or #hard_washable_items > 0
            if not any_washable_items_at_all then
                 gapi.add_msg(locale.gettext("You have no items that can be washed."))
            else
                 gapi.add_msg(locale.gettext("You have no items suitable for this washing method."))
            end
            return 0 -- No items to display for this specific washing method
        end

        local done_option_key = current_ui_key
        ui:add(done_option_key, locale.gettext("Done Washing Selected Items"))

        local eidx = ui:query()

        if eidx < 1 then -- User closed the UI (e.g., Esc)
            gapi.add_msg(locale.gettext("Washing canceled."))
            return 0
        end

        if eidx == done_option_key then -- Player selected "Done"
            local final_selected_items_list = {}
            for item_obj_selected, _ in pairs(selected_item_object_set) do
                table.insert(final_selected_items_list, item_obj_selected)
            end

            if #final_selected_items_list == 0 then
                gapi.add_msg(locale.gettext("No items were selected to wash."))
            else
                gapi.add_msg(locale.gettext("Proceeding to wash selected items..."))
                local items_washed_count = 0
                for _, item_to_wash in ipairs(final_selected_items_list) do
                    mod.wash_item(item_to_wash)
                    items_washed_count = items_washed_count + 1
                end
                if items_washed_count > 0 then
                    gapi.add_msg(string.format(locale.gettext("Finished washing %d item(s)."), items_washed_count))
                end
            end
            return 1 -- Consumes a turn as the washing action/decision is complete
        end

        -- An item line was selected, toggle its selection status
        local toggled_item_obj = current_loop_ui_key_to_item_map[eidx]
        if toggled_item_obj then
            if selected_item_object_set[toggled_item_obj] then
                selected_item_object_set[toggled_item_obj] = nil -- Deselect
            else
                selected_item_object_set[toggled_item_obj] = true -- Select
            end
        else
            -- This should not happen if current_loop_ui_key_to_item_map is built correctly
            -- and eidx is a valid key from ui:query() that isn't the "Done" key.
            gapi.add_msg(locale.gettext("Error: UI selection mismatch. Please try again or report this bug."))
        end
        -- The loop will continue, and the UI will be rebuilt with updated asterisks.
    end
end

mod.on_every_x_check_washed = function()
    local who = gapi.get_avatar():as_character()
    local all_items = who:all_items(true)
    local total_worn_items = 0
    local washed_items = 0

    for _, item in ipairs(all_items) do
        -- Skip items that are not worn or are not armor
        if not mod.is_worn_by_player(item) or not item:is_armor() then
            goto continue_loop
        end
        total_worn_items = total_worn_items + 1
        if item:has_flag(wash_flag_id) then
            washed_items = washed_items + 1
        end
        ::continue_loop::
    end

    local clean_percent = (total_worn_items > 0) and (washed_items / total_worn_items * 100) or 0
    local mood_intensity = 0

    if washed_items < 3 then
        -- If less than 3 items are washed, mood effect is not applied
        mood_intensity = 0
    elseif clean_percent >= 67 then
        mood_intensity = 3
    elseif clean_percent >= 34 then
        mood_intensity = 2
    elseif clean_percent > 0 then
        mood_intensity = 1
    end

    -- Apply or remove the effect based on calculated intensity
    if mood_intensity > 0 then
        -- Ensure the effect is active with the correct intensity.
        -- Duration is ignored for permanent effects, but we need to provide one.
        who:add_effect(mood_effect_id, TimeDuration.from_turns(1), nil, mood_intensity)
    else
        -- Remove the effect if intensity should be 0
        who:remove_effect(mood_effect_id)
    end
end