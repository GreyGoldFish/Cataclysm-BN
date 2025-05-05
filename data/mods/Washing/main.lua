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

mod.iuse_wash_action = function( who, item, pos )
    local all_items = who:all_items(true)
    
    for i, item_to_wash in ipairs(all_items) do
        if item_to_wash:is_armor() then
            item_to_wash:set_flag( wash_flag_id, true )
        end
    end

    return 1
end