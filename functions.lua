local izi = require("common/izi_sdk")
local enums = require("common/enums")
local spells = require("spells")
local lists = require("lists")
local menu = require("menu")
local Functions = {}

-- Party cache (refreshed once per tick via update_party_cache)
local cached_party = {}

function Functions.update_party_cache()
    cached_party = izi.party(100)
end

function Functions.get_cached_party()
    return cached_party
end

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

local dispel_queue = {}
local last_dispel_check = 0

function Functions.check_all_dispels(range)
    if not menu.AUTO_DISPEL or not menu.AUTO_DISPEL:get_state() then
        return nil, nil, nil
    end

    local nat_up = spells.EXPUNGE:is_learned() and spells.EXPUNGE:cooldown_up()
    local caut_up = spells.CAUTERIZING_FLAME:is_learned() and spells.CAUTERIZING_FLAME:cooldown_up()

    -- Early return to save performance if no dispels are actually ready
    if not (nat_up or caut_up) then
        return nil, nil, nil
    end

    -- Throttle expensive aura checks to 4 times a second (0.25s) using core elapsed time to save FPS
    local now = core.time()
    if now - last_dispel_check < 0.25 then
        return nil, nil, nil
    end
    last_dispel_check = now

    range = range or 30
    local allies = cached_party

    local current_active = {}
    local ready_ally, ready_buff, ready_type = nil, nil, nil

    for _, ally in ipairs(allies) do
        if Functions.validate_unit(ally, range) then
            local guid = tostring(ally:get_guid())

            -- 1. Check special whitelist (private/hidden auras)
            local auras = ally:get_auras()
            if auras then
                for _, aura in ipairs(auras) do
                    if aura.buff_id and lists.SPECIAL_DISPELS and lists.SPECIAL_DISPELS[aura.buff_id] then
                        local buff_id = aura.buff_id
                        local q_key = guid .. "_" .. tostring(buff_id)
                        current_active[q_key] = true

                        if not dispel_queue[q_key] then
                            dispel_queue[q_key] = now + (math.random(80, 120) / 100)
                        end

                        if not ready_ally and now >= dispel_queue[q_key] then
                            ready_ally, ready_buff, ready_type = ally, buff_id, aura.type
                        end
                    end
                end
            end

            -- 2. Check standard dispellable debuffs
            local debuffs = ally:get_debuffs()
            if debuffs then
                for _, debuff in pairs(debuffs) do
                    local t = debuff.type
                    if t == enums.buff_type.POISON or
                        t == enums.buff_type.CURSE or
                        t == enums.buff_type.DISEASE then
                        local buff_id = debuff.buff_id or 0
                        local q_key = guid .. "_" .. tostring(buff_id)
                        current_active[q_key] = true

                        if not dispel_queue[q_key] then
                            dispel_queue[q_key] = now + (math.random(80, 120) / 100)
                        end

                        if not ready_ally and now >= dispel_queue[q_key] then
                            ready_ally, ready_buff, ready_type = ally, buff_id, t
                        end
                    end
                end
            end
        end
    end

    -- Cleanup dispel_queue for debuffs that are no longer active
    for key, _ in pairs(dispel_queue) do
        if not current_active[key] then
            dispel_queue[key] = nil
        end
    end

    return ready_ally, ready_buff, ready_type
end

return Functions
