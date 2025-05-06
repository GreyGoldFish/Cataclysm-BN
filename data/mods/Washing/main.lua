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
local mood_effect_id = EffectTypeId.new( "eff_clean_clothes_mood" )

local wash_item = function (item)
    item:set_flag(wash_flag_id)
    item:set_var_str("item_label", "<color_white>" .. item:tname(1, false, 0) .. locale.gettext(" (washed)") .. "</color>")
end

local sully_item = function (item)
    item:remove_flag(wash_flag_id)
    item:erase_var("item_label")
end

mod.iuse_wash_action = function( who, item, pos )
    local all_items = who:all_items(true)
    local soft_washable_items = {}
    local fragile_washable_items = {}
    local hard_washable_items = {}

    for _, item_to_wash in ipairs(all_items) do
        -- Continue loop if the item isn't armor or is already washed
        if not item_to_wash:is_armor() or item_to_wash:has_flag( wash_flag_id ) then
            goto continue_loop
        end
        -- Check if the item is soft
        if item_to_wash:is_soft() then
            table.insert( soft_washable_items, item_to_wash )
        -- Check if the item is fragile
        elseif item_to_wash:has_flag( fragile_flag_id ) then
            table.insert( fragile_washable_items, item_to_wash )
        -- If none of the above, it must be hard
        else
            table.insert( hard_washable_items, item_to_wash )
        end
        ::continue_loop::
    end

    local ui = UiList.new()
    ui:title(locale.gettext("Select items to wash"))
    -- Combine all items into one list for the menu, keeping track of the original item object
    local all_washable_items = {}
    local current_index = 1
    if item:has_flag( washes_soft_flag_id ) then
        for _, item_obj in ipairs(soft_washable_items) do
            ui:add(current_index, item_obj:display_name(1))
            table.insert(all_washable_items, item_obj)
            current_index = current_index + 1
        end
    end
    if item:has_flag( washes_fragile_flag_id ) then
        for _, item_obj in ipairs(fragile_washable_items) do
            ui:add(current_index, item_obj:display_name(1))
            table.insert(all_washable_items, item_obj)
            current_index = current_index + 1
        end
    end
    if item:has_flag( washes_hard_flag_id ) then
        for _, item_obj in ipairs(hard_washable_items) do
            ui:add(current_index, item_obj:display_name(1))
            table.insert(all_washable_items, item_obj)
            current_index = current_index + 1
        end
    end

    -- Check if there's anything to wash before querying
    if #all_washable_items == 0 then
        gapi.add_msg(locale.gettext("You have no items to wash."))
        return 0
    end

    -- eidx will be the index (1-based) from the combined list
    local eidx = ui:query()

    -- Canceled by player
    if eidx < 1 then
        gapi.add_msg(locale.gettext("Never mind."))
        return 0
    end

    -- Get the selected item object from the combined list
    local selected_item = all_washable_items[eidx]

    gapi.add_msg(locale.gettext("You wash the ") .. selected_item:display_name(1) .. locale.gettext(".") )
    wash_item(selected_item)

    -- Consume charge from the tool
    -- item:ammo_consume( item:ammo_default(), 1 )
    -- TODO: Add check for tool running out of charges

    return 1
end

mod.is_worn_by_player = function(item)
    local who = gapi.get_avatar():as_character()
    if not who then return false end -- Ensure player exists
    return who:is_worn(item) and item:is_armor()
end

mod.on_every_x_check_washed = function()
    local who = gapi.get_avatar():as_character()
    local all_items = who:all_items(true)
    local total_worn_items = 0
    local clean_items = 0

    for _, item in ipairs(all_items) do
        -- Skip items that are not worn or are not armor
        if not mod.is_worn_by_player(item) or not item:is_armor() then
            goto continue_loop
        end
        total_worn_items = total_worn_items + 1
        if item:has_flag(wash_flag_id) then
            clean_items = clean_items + 1
        end
        ::continue_loop::
    end

    local clean_percent = (total_worn_items > 0) and (clean_items / total_worn_items * 100) or 0
    local mood_intensity = 0

    if clean_items < 3 then
        -- If less than 3 items are clean, mood effect is not applied
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