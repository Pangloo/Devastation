local color = require("common/color")
local vec2 = require("common/geometry/vector_2")
local enums = require("common/enums")
local menu = require("menu")

local UI = {}
local window_size = vec2.new(280, 80)
local button_size = vec2.new(60, 60)
local spacing = 5
local padding = 10
local win = nil

local color_enabled = color.new(201, 156, 86, 200)
local color_disabled = color.new(100, 100, 100, 200)
local color_text = color.new(255, 255, 255, 255)
local color_bg = color.new(0, 0, 0, 200)
local color_border = color.new(255, 255, 255, 50)

function UI.draw()
    if not win then
        win = core.menu.window("Devastation Hotbar")
        win:set_initial_size(window_size)
        win:set_initial_position(vec2.new(500, 500))
    end
    if win and menu.SHOW_HOTBAR then
        win:set_visibility(menu.SHOW_HOTBAR:get_state())
    end
    local tooltip_to_draw = nil
    win:set_next_window_padding(vec2.new(0, 0))
    win:set_next_window_items_spacing(vec2.new(0, 0))

    win:begin(enums.window_enums.window_resizing_flags.NO_RESIZE, false, color_bg, color_border,
        enums.window_enums.window_cross_visuals.BLUE_THEME, function()
        local current_x = padding
        local current_y = padding
        local p_min = vec2.new(current_x, current_y)
        local p_max = vec2.new(current_x + button_size.x, current_y + button_size.y)
        local function draw_btn(text, menu_item, p_min, p_max, tooltip_text)
            local is_on = menu_item:get_state()
            local bg_color = is_on and color_enabled or color_disabled
            win:render_rect_filled(p_min, p_max, bg_color, 5)
            if win:is_rect_clicked(p_min, p_max) then menu_item:set(not is_on) end
            if win:is_mouse_hovering_rect(p_min, p_max) and tooltip_text then tooltip_to_draw = tooltip_text end
            local text_size = win:get_text_size(text)
            local txt_offset = vec2.new(p_min.x + (button_size.x - text_size.x) / 2, p_min.y + (button_size.y - text_size.y) / 2)
            win:render_text(0, txt_offset, color_text, text)
        end

        draw_btn("Toggle", menu.ROTATION_ENABLED, p_min, p_max, "Enable and disable rotation")
        current_x = current_x + button_size.x + spacing
        p_min = vec2.new(current_x, current_y)
        p_max = vec2.new(current_x + button_size.x, current_y + button_size.y)
        draw_btn("CDs", menu.USE_COOLDOWNS, p_min, p_max, "Toggle Use Cooldowns")
        current_x = current_x + button_size.x + spacing
        p_min = vec2.new(current_x, current_y)
        p_max = vec2.new(current_x + button_size.x, current_y + button_size.y)
        draw_btn("Intr", menu.AUTO_INTERRUPT, p_min, p_max, "Toggle Auto Interrupt")
        current_x = current_x + button_size.x + spacing
        p_min = vec2.new(current_x, current_y)
        p_max = vec2.new(current_x + button_size.x, current_y + button_size.y)
        draw_btn("Dispel", menu.AUTO_DISPEL, p_min, p_max, "Toggle Auto Dispel")

        if tooltip_to_draw then
            local t_width = string.len(tooltip_to_draw) * 7 + 10
            win:begin_popup(color_bg, color_border, vec2.new(t_width, 24), vec2.new(10, -35), false, false, function()
                win:render_text(0, vec2.new(5, 5), color_text, tooltip_to_draw)
            end)
        end
    end)
end
return UI
