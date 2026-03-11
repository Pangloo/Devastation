local izi = require("common/izi_sdk")
local plugin = require("header")
if not plugin.load then return end

local spells = require("spells")
local funcs = require("functions")
local menu = require("menu")
local ui = require("ui")

local callback = {}

callback.quell = function()
    if not menu.AUTO_INTERRUPT:get_state() then return false end
    if not spells.QUELL:is_learned() or not spells.QUELL:cooldown_up() then return false end
    local target = funcs.get_interrupt_target(25)
    if target then
        return spells.QUELL:cast(target, "Quell")
    end
    return false
end

callback.dragonrage = function(target)
    if not menu.USE_COOLDOWNS:get_state() then return false end
    if not spells.DRAGONRAGE:is_learned() or not spells.DRAGONRAGE:cooldown_up() then return false end
    local me = izi.me()
    return spells.DRAGONRAGE:cast(me, "Dragonrage", { skip_facing = true })
end

callback.hover_movement = function()
    if not spells.HOVER:is_learned() or not spells.HOVER:cooldown_up() then return false end
    local me = izi.me()
    if me:is_moving() and not me:has_buff(358267) then
        return spells.HOVER:cast(me, "Hover", { skip_facing = true })
    end
    return false
end

callback.tip_the_scales = function()
    if not menu.USE_COOLDOWNS:get_state() then return false end
    if not spells.TIP_THE_SCALES:is_learned() or not spells.TIP_THE_SCALES:cooldown_up() then return false end
    local me = izi.me()
    if me:has_buff(375087) then -- If Dragonrage is up
        return spells.TIP_THE_SCALES:cast(me, "Tip the Scales", { skip_facing = true })
    end
    return false
end

callback.eternity_surge = function(target, active_enemies)
    if not spells.ETERNITY_SURGE:is_learned() or not spells.ETERNITY_SURGE:cooldown_up() then return false end
    if not funcs.can_cast_moving() then return false end

    local empower_level = 1
    if active_enemies > 1 then empower_level = 2 end
    if active_enemies > 2 then empower_level = 3 end

    return izi.cast_charge_spell(spells.ETERNITY_SURGE, empower_level, target, "Eternity Surge")
end

callback.fire_breath = function(target)
    if not spells.FIRE_BREATH:is_learned() or not spells.FIRE_BREATH:cooldown_up() then return false end
    if not funcs.can_cast_moving() then return false end
    local me = izi.me()
    return izi.cast_charge_spell(spells.FIRE_BREATH, 1, me, "Fire Breath")
end

callback.deep_breath = function(target)
    if not menu.USE_COOLDOWNS:get_state() then return false end
    if not spells.DEEP_BREATH:is_learned() or not spells.DEEP_BREATH:cooldown_up() then return false end
    return spells.DEEP_BREATH:cast_position(target:get_position(), "Deep Breath")
end

callback.pyre = function(target, active_enemies)
    if not spells.PYRE:is_learned() or not spells.PYRE:cooldown_up() then return false end
    if not funcs.can_cast_moving() then return false end
    local me = izi.me()
    local essence = me:get_power(19)
    if essence >= 2 then
        return spells.PYRE:cast(target, "Pyre")
    end
    return false
end

callback.disintegrate = function(target)
    if not spells.DISINTEGRATE:is_learned() or not funcs.can_cast_moving() then return false end
    if not spells.DISINTEGRATE:cooldown_up() then return false end
    local me = izi.me()
    local essence = me:get_power(19)
    local has_eb = me:has_buff(359618)
    if essence >= 3 or has_eb then
        return spells.DISINTEGRATE:cast(target, "Disintegrate")
    end
    return false
end

callback.azure_sweep = function(target)
    if not spells.AZURE_SWEEP:is_learned() or not spells.AZURE_SWEEP:cooldown_up() then return false end
    if not spells.AZURE_SWEEP:cooldown_up() then return false end
    return spells.AZURE_SWEEP:cast(target, "Azure Sweep")
end

callback.living_flame = function(target)
    if not spells.LIVING_FLAME:is_learned() or not funcs.can_cast_moving() then return false end
    if not spells.LIVING_FLAME:cooldown_up() then return false end
    return spells.LIVING_FLAME:cast(target, "Living Flame")
end

callback.azure_strike = function(target)
    if not spells.AZURE_STRIKE:is_learned() or not spells.AZURE_STRIKE:cooldown_up() then return false end
    return spells.AZURE_STRIKE:cast(target, "Azure Strike")
end


local actionList = {}

actionList.dps = function()
    local target = funcs.get_dps_target(25)
    if not target then return false end

    local active_enemies = funcs.get_active_enemies(25)

    --if callback.hover_movement() then return true end
    if callback.dragonrage(target) then return true end
    if callback.tip_the_scales() then return true end

    -- basic aoe logic vs st logic
    if active_enemies >= 3 then
        if callback.deep_breath(target) then return true end
        if callback.eternity_surge(target, active_enemies) then return true end
        if callback.fire_breath(target) then return true end
        if callback.pyre(target, active_enemies) then return true end
        if callback.azure_sweep(target) then return true end
        if callback.azure_strike(target) then return true end
    else
        -- single target logic
        if callback.eternity_surge(target, active_enemies) then return true end
        if callback.fire_breath(target) then return true end
        if callback.pyre(target, active_enemies) then return true end -- Only if mass disintegrate isn't up
        if callback.disintegrate(target) then return true end
        if callback.azure_sweep(target) then return true end
        if callback.living_flame(target) then return true end
        if callback.azure_strike(target) then return true end
    end
    return false
end

local function on_update()
    local me = izi.me()
    if not me or not me:is_valid() or me:is_mounted() or me:is_dead_or_ghost() then return end

    if not menu.is_enabled() then return end
    if not menu.is_rotation_enabled() then return end

    if me:is_casting() or me:is_channeling() then
        local channel_id = me:get_active_channel_spell_id()
        if channel_id == 356995 and me:get_channeling_or_casting_remaining_ms() < 150 then
            -- Let it finish
        else
            return false
        end
    end

    if me:affecting_combat() then
        funcs.autotarget()
        if callback.quell() then return end
        if actionList.dps() then return end
    end
end

local function on_render()
    menu.draw()
end

core.register_on_update_callback(on_update)
core.register_on_render_menu_callback(on_render)
core.register_on_render_window_callback(ui.draw)

core.log("[Devastation Reality] " .. plugin.version .. " Loaded successfully!")
