gdebug.log_info("Washing: preload.")

-- Have to register iuse before data loading.
-- Actual implementation (function mod.iuse_function) will be defined later.

local mod = game.mod_runtime[game.current_mod]

game.iuse_functions["WASH"] = function(...)
  return mod.iuse_wash_action(...)
end

gapi.add_on_every_x_hook(TimeDuration.from_turns(1), function(...)
  return mod.on_every_x_check_washed(...)
end)