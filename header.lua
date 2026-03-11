local plugin = {}

plugin.name = "Devastation Reality"
plugin.version = "1.0.0"
plugin.author = "Antigravity"
plugin.load = true

local local_player = core.object_manager.get_local_player()
if not local_player then
    plugin.load = false
    return plugin
end

local enums = require("common/enums")
local player_class = local_player:get_class()
local is_valid_class = player_class == enums.class_id.EVOKER

if not is_valid_class then
    plugin.load = false
    return plugin
end

-- Validate specialization is Devastation (spec_id = 1)
local player_spec_id = core.spell_book.get_specialization_id()
local is_valid_spec_id = player_spec_id == 1

if not is_valid_spec_id then
    plugin.load = false
    return plugin
end

return plugin
