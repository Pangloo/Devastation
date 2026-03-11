local izi = require("common/izi_sdk")
local enums = require("common/enums")
local spells = require("spells")
local menu = require("menu")
local Functions = {}

function Functions.validate_unit(unit, range)
    if not unit or not unit:is_valid() or unit:is_dead() then return false end
    if range and unit:distance() > range then return false end
    return true
end

function Functions.validate_enemy(unit, range)
    if unit:get_npc_id() == 241517 or unit:get_npc_id() == 234478 or unit:get_npc_id() == 233824 or unit:get_npc_id() == 234627 then return true end
    if not unit or not unit:is_valid() or unit:is_dead() then return false end
    if not range then range = 25 end
    if range and unit:distance() > range then return false end
    local me = izi.me()
    if me and not me:is_looking_at(unit) then return false end
    return true
end

function Functions.can_cast_moving()
    local me = izi.me()
    if not me then return false end
    return not me:is_moving() or me:has_buff(358267) -- HOVER
end

function Functions.get_dps_target(range)
    local target = izi.me():get_target()
    if target and Functions.validate_enemy(target, range) then
        return target
    end
    local enemies = izi.enemies(range or 25)
    local best_enemy = nil
    local min_dist = 999
    for _, enemy in ipairs(enemies) do
        if Functions.validate_enemy(enemy, range) then
            local dist = enemy:distance()
            if dist < min_dist then
                min_dist = dist
                best_enemy = enemy
            end
        end
    end
    return best_enemy
end

function Functions.get_interrupt_target(range)
    local enemies = izi.enemies(range or 25)
    local now = core.game_time()
    for _, enemy in ipairs(enemies) do
        if Functions.validate_enemy(enemy, range) then
            if enemy:is_casting_spell() and enemy:is_active_spell_interruptable() then
                local start_time = enemy:get_active_spell_cast_start_time()
                local end_time = enemy:get_active_spell_cast_end_time()
                if start_time and end_time and end_time > start_time then
                    local pct = ((now - start_time) / (end_time - start_time)) * 100
                    if pct >= 30 and pct <= 60 then
                        return enemy
                    end
                end
            elseif enemy:is_channelling_spell() and enemy:is_active_spell_interruptable() then
                local start_time = enemy:get_active_channel_cast_start_time()
                local end_time = enemy:get_active_channel_cast_end_time()
                if start_time and end_time and end_time > start_time then
                    local pct = ((now - start_time) / (end_time - start_time)) * 100
                    if pct >= 10 and pct <= 40 then
                        return enemy
                    end
                end
            end
        end
    end
    return nil
end

function Functions.autotarget()
    local me = izi.me()
    if not me or not me:affecting_combat() then return false end

    local target = me:get_target()
    if target and target:is_valid() and not target:is_dead() then return false end 

    local best, min_dist = nil, math.huge
    local enemies = izi.enemies(25)
    for _, enemy in ipairs(enemies) do
        if Functions.validate_enemy(enemy, 25) then
            local d = enemy:distance()
            if d < min_dist then
                best = enemy
                min_dist = d
            end
        end
    end
    if best then
        core.input.set_target(best)
        return true
    end
    return false
end

function Functions.get_active_enemies(range)
    local enemies = izi.enemies(range or 25)
    local count = 0
    for _, enemy in ipairs(enemies) do
        if Functions.validate_enemy(enemy, range) then
            count = count + 1
        end
    end
    return count
end

return Functions
