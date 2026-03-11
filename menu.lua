local core = _G.core
local Menu = {}
local ID = "devastation_reality_"

local main_tree = core.menu.tree_node()
local tree_general = core.menu.tree_node()
local tree_cooldowns = core.menu.tree_node()
local tree_defensives = core.menu.tree_node()
local tree_utility = core.menu.tree_node()

Menu.ENABLED = core.menu.checkbox(true, ID .. "enabled")
Menu.ROTATION_ENABLED = core.menu.checkbox(true, ID .. "rot_enabled")
Menu.SHOW_HOTBAR = core.menu.checkbox(true, ID .. "show_hotbar")

Menu.AUTO_INTERRUPT = core.menu.checkbox(true, ID .. "auto_interrupt")
Menu.AUTO_DISPEL = core.menu.checkbox(true, ID .. "auto_dispel")

Menu.USE_COOLDOWNS = core.menu.checkbox(true, ID .. "use_cooldowns")

Menu.USE_DEFENSIVES = core.menu.checkbox(true, ID .. "use_defensives")

function Menu.draw()
    main_tree:render("Devastation Reality", function()
        tree_general:render("General", function()
            Menu.ENABLED:render("Enable Plugin")
            Menu.ROTATION_ENABLED:render("Enable Rotation")
            Menu.SHOW_HOTBAR:render("Show Hotbar")
        end)
        tree_cooldowns:render("Cooldowns", function()
            Menu.USE_COOLDOWNS:render("Use Cooldowns")
        end)
        tree_defensives:render("Defensives", function()
            Menu.USE_DEFENSIVES:render("Use Defensives")
        end)
        tree_utility:render("Utility", function()
            Menu.AUTO_INTERRUPT:render("Auto Interrupt")
            Menu.AUTO_DISPEL:render("Auto Dispel")
        end)
    end)
end

function Menu.is_enabled() return Menu.ENABLED:get_state() end
function Menu.is_rotation_enabled() return Menu.ROTATION_ENABLED:get_state() end

return Menu
