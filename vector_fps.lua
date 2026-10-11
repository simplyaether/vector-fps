-- Vector FPS v1 :: Hypershot / RIVALS / Blood Zone
-- Vector Lua Engine (projectvector.cc/lua)

local PLACES = {
    [17516596118] = "Hypershot",
    [17625359962] = "RIVALS",
    [13955927965] = "Blood Zone",
}

local function okc(fn, ...)
    local s, a, b, c = pcall(fn, ...)
    if s then return a, b, c end
    return nil
end

local function mem(o, k)
    if o == nil then return nil end
    return okc(function() return o[k] end)
end

local function inv(o, names, ...)
    for i = 1, #names do
        local m = mem(o, names[i])
        if type(m) == "function" then
            local a, b, c = okc(m, o, ...)
            if a ~= nil then return a, b, c end
            a, b, c = okc(m, ...)
            if a ~= nil then return a, b, c end
        end
    end
    return nil
end

local function vxyz(v)
    if v == nil then return nil end
    local x = mem(v, "x") or mem(v, "X")
    local y = mem(v, "y") or mem(v, "Y")
    local z = mem(v, "z") or mem(v, "Z")
    if type(x) == "number" and type(y) == "number" and type(z) == "number" then
        return x, y, z
    end
    return nil
end

local function vnew(x, y, z)
    local v = okc(function() return Vector3.new(x, y, z) end)
    if v ~= nil then return v end
    return okc(function() return Vector3(x, y, z) end)
end

local function vdist(a, b)
    local ax, ay, az = vxyz(a)
    local bx, by, bz = vxyz(b)
    if not ax or not bx then return math.huge end
    local dx, dy, dz = ax - bx, ay - by, az - bz
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function place_id()
    local pid = mem(game, "place_id") or mem(game, "PlaceId")
    if type(pid) == "number" then return pid end
    pid = inv(game, { "get_place_id", "getPlaceId", "GetPlaceId" })
    if type(pid) == "number" then return pid end
    return 0
end

local MY_PLACE = place_id()
local GAME_NAME = PLACES[MY_PLACE] or "Unknown"
local TEAM_DEF = (GAME_NAME == "Hypershot" or GAME_NAME == "RIVALS")

-- ---------------------------------------------------------------- menu ---

local TAB = "Vector FPS"
menu.add_tab(TAB, "V")

menu.add_group(TAB, "ESP")
menu.add_checkbox(TAB, "ESP", "esp_on",    "Enable ESP",       true)
menu.add_checkbox(TAB, "ESP", "esp_box",   "Bounding box",     true)
menu.add_checkbox(TAB, "ESP", "esp_corner","Corner box",       false)
menu.add_checkbox(TAB, "ESP", "esp_name",  "Name",             true)
menu.add_checkbox(TAB, "ESP", "esp_hp",    "Health bar",       true)
menu.add_checkbox(TAB, "ESP", "esp_dist",  "Distance",         true)
menu.add_checkbox(TAB, "ESP", "esp_skel",  "Skeleton",         false)
menu.add_checkbox(TAB, "ESP", "esp_chams", "Chams",            false)
menu.add_checkbox(TAB, "ESP", "esp_arrow", "Off-screen arrow", true)
menu.add_checkbox(TAB, "ESP", "esp_snap",  "Snaplines",        false)
menu.add_checkbox(TAB, "ESP", "esp_team",  "Hide teammates",   TEAM_DEF)
menu.add_checkbox(TAB, "ESP", "esp_vis",   "Visible only",     false)

menu.add_group(TAB, "Aim")
menu.add_checkbox(TAB, "Aim", "aim_on",   "Silent aim",        true)
menu.add_checkbox(TAB, "Aim", "aim_fovc", "FOV circle",        true)
menu.add_checkbox(TAB, "Aim", "aim_head", "Aim at head",       true)
menu.add_checkbox(TAB, "Aim", "aim_lmb",  "Hold LMB to aim",   true)
menu.add_checkbox(TAB, "Aim", "aim_team", "Team check",        TEAM_DEF)
menu.add_checkbox(TAB, "Aim", "aim_vis",  "Visibility check",  true)

menu.add_group(TAB, "Misc")
menu.add_checkbox(TAB, "Misc", "misc_wm",     "Watermark",       true)
menu.add_checkbox(TAB, "Misc", "misc_cross",  "Crosshair",       true)
menu.add_checkbox(TAB, "Misc", "misc_fov_on", "Custom FOV",      false)
menu.add_checkbox(TAB, "Misc", "misc_hb_on",  "Hitbox expander", false)
menu.add_checkbox(TAB, "Misc", "misc_valp",   "Value panel",     true)

-- value panel (engine menu only documents checkboxes, so numbers are drawn) ---

local VALUES = {
    { id = "aim_fov",  label = "Aim FOV",      val = 220,  min = 40,   max = 600,  step = 10 },
    { id = "aim_dist", label = "Aim distance", val = 900,  min = 50,   max = 2000, step = 50 },
    { id = "esp_maxd", label = "ESP distance", val = 1500, min = 50,   max = 3000, step = 50 },
    { id = "fov_val",  label = "Game FOV",     val = 90,   min = 60,   max = 120,  step = 1 },
    { id = "hb_size",  label = "Hitbox size",  val = 6,    min = 2,    max = 15,   step = 0.5 },
}
local V = {}
for i = 1, #VALUES do V[VALUES[i].id] = VALUES[i].val end

local drag_row = nil

local function mouse_pos()
    local a, b = utility.get_mouse_pos()
    if type(a) == "number" and type(b) == "number" then return a, b end
    if type(a) == "table" or type(a) == "userdata" then
        local x, y = vxyz(a)
        if x then return x, y end
        local X = mem(a, "X") or mem(a, "x")
        local Y = mem(a, "Y") or mem(a, "y")
        if type(X) == "number" and type(Y) == "number" then return X, Y end
    end
    local loc = okc(function()
        return game:GetService("UserInputService"):GetMouseLocation()
    end)
    if loc then
        local X, Y = vxyz(loc)
        if X then return X, Y end
    end
    return 0, 0
end

local function mouse_down()
    for _, n in ipairs({ "is_key_down", "isKeyDown", "IsKeyDown" }) do
        local f = mem(input, n)
        if type(f) == "function" then
            local r = okc(f, input, 0x01)
            if type(r) == "boolean" then return r end
            r = okc(f, 0x01)
            if type(r) == "boolean" then return r end
        end
    end
    return false
end

local function screen_center()
    local f = mem(input, "get_screen_center") or mem(input, "getScreenCenter")
        or mem(input, "GetScreenCenter")
    if type(f) == "function" then
        local a, b = okc(f, input)
        if type(a) ~= "number" then a, b = okc(f) end
        if type(a) == "number" and type(b) == "number" then return a, b end
    end
    local w, h = utility.get_screen_size()
    return (w or 0) * 0.5, (h or 0) * 0.5
end

local function draw_values(mdown, mx, my)
    local sw, sh = utility.get_screen_size()
    local x = (sw or 800) - 232
    local y0 = 96
    local rowh = 30
    local bw = 150
    local ac = { 0.25, 0.75, 1, 1 }
    local dim = { 0.5, 0.5, 0.5, 1 }
    local bg = { 0, 0, 0, 0.75 }

    local h = 24 + #VALUES * rowh + 8
    for dx = 0, 224, 4 do draw.line(x + dx, y0, x + dx, y0 + h, bg, 2) end
    draw.text(x + 6, y0 + 5, "VALUES  " .. GAME_NAME, ac, 12)

    for i = 1, #VALUES do
        local g = VALUES[i]
        local ry = y0 + 24 + (i - 1) * rowh
        draw.text(x + 6, ry, g.label, { 1, 1, 1, 0.9 }, 11)
        local bx, by = x + 6, ry + 18
        draw.line(bx, by, bx + bw, by, dim, 3)
        local frac = (g.val - g.min) / (g.max - g.min)
        draw.line(bx, by, bx + bw * frac, by, ac, 3)
        draw.text(bx + bw + 8, ry + 14, tostring(g.val), { 1, 1, 1, 0.8 }, 10)

        if mdown and mx >= bx - 4 and mx <= bx + bw + 4 and my >= by - 7 and my <= by + 7 then
            drag_row = g
        end
        if drag_row == g then
            if not mdown then
                drag_row = nil
            else
                local f = (mx - bx) / bw
                if f < 0 then f = 0 end
                if f > 1 then f = 1 end
                local v = g.min + (g.max - g.min) * f
                v = math.floor(v / g.step + 0.5) * g.step
                if v < g.min then v = g.min end
                if v > g.max then v = g.max end
                g.val = v
                V[g.id] = v
            end
        end
    end
end

-- ------------------------------------------------------------ teamwork ---

local function player_inst(p)
    local pl = mem(p, "player") or mem(p, "Player")
    if pl ~= nil then return pl end
    local ps = mem(game, "players") or mem(game, "Players")
        or inv(game, { "get_service", "getService", "GetService" }, "Players")
    if ps ~= nil then
        return inv(ps, { "find_first_child", "findFirstChild", "FindFirstChild" }, p.name)
    end
    return nil
end

local function team_of(inst)
    if inst == nil then return nil end
    local t = mem(inst, "Team") or mem(inst, "team")
    if t ~= nil then return "T:" .. tostring(mem(t, "Name") or mem(t, "name") or t) end
    local tc = mem(inst, "TeamColor") or mem(inst, "team_color")
    if tc ~= nil then return "C:" .. tostring(tc) end
    return nil
end

local function is_teammate(p)
    local lp = entity.get_local_player()
    if lp == nil or p == nil then return false end
    local t1 = team_of(player_inst(p))
    local t2 = team_of(player_inst(lp))
    if t1 ~= nil and t2 ~= nil then return t1 == t2 end
    local pt = team_of(p)
    local lt = team_of(lp)
    if pt ~= nil and lt ~= nil then return pt == lt end
    return false
end

local function is_visible(p)
    local ch = mem(p, "character") or mem(p, "Character")
    if ch == nil then return true end
    local addr = mem(ch, "address") or mem(ch, "Address")
    if addr == nil then return true end
    local f = mem(raycast, "is_player_visible") or mem(raycast, "isPlayerVisible")
        or mem(raycast, "IsPlayerVisible")
    if type(f) ~= "function" then return true end
    local r = okc(f, raycast, addr)
    if r == nil then r = okc(f, addr) end
    if type(r) ~= "boolean" then return true end
    return r
end

-- --------------------------------------------------------------- bones ---

local BONE_PAIRS = {
    { "Head", "UpperTorso" }, { "Head", "Torso" },
    { "UpperTorso", "LowerTorso" },
    { "Torso", "Left Arm" }, { "Torso", "Right Arm" },
    { "Left Arm", "Left Hand" }, { "Right Arm", "Right Hand" },
    { "LowerTorso", "Left Leg" }, { "LowerTorso", "Right Leg" },
    { "Left Leg", "Left Foot" }, { "Right Leg", "Right Foot" },
    { "UpperTorso", "LeftUpperArm" }, { "UpperTorso", "RightUpperArm" },
    { "LeftUpperArm", "LeftLowerArm" }, { "RightUpperArm", "RightLowerArm" },
    { "LeftLowerArm", "LeftHand" }, { "RightLowerArm", "RightHand" },
    { "LowerTorso", "LeftUpperLeg" }, { "LowerTorso", "RightUpperLeg" },
    { "LeftUpperLeg", "LeftLowerLeg" }, { "RightUpperLeg", "RightLowerLeg" },
    { "LeftLowerLeg", "LeftFoot" }, { "RightLowerLeg", "RightFoot" },
    { "Torso", "Left Hand" }, { "Torso", "Right Hand" },
    { "Left Hand", "Left Arm" },
}

local function bone_map(p)
    local raw = okc(function() return p:get_bones_screen() end)
    if type(raw) ~= "table" then return nil end
    local map = {}

    local function put(name, e)
        if type(name) ~= "string" then return end
        local x, y = vxyz(e)
        if not x then
            x = mem(e, "x") or mem(e, "X")
            y = mem(e, "y") or mem(e, "Y")
        end
        if type(x) ~= "number" or type(y) ~= "number" then return end
        local v = mem(e, "visible")
        if v == nil then v = mem(e, "vis") end
        if v == nil and type(e[3]) ~= "nil" then v = e[3] end
        map[name] = { x = x, y = y, vis = v == nil and true or v and true or false }
    end

    for k, e in pairs(raw) do
        if type(e) == "table" or type(e) == "userdata" then
            if type(e[1]) == "number" and type(e[2]) == "number" then
                put(mem(e, "name") or mem(e, "Name") or (type(k) == "string" and k),
                    { x = e[1], y = e[2], visible = e[3] })
            else
                put(mem(e, "name") or mem(e, "Name") or (type(k) == "string" and k), e)
            end
        end
    end
    if next(map) == nil then return nil end
    return map
end

-- --------------------------------------------------------------- parts ---

local part_warned = false

local function part_set_size(inst, size)
    if inst == nil then return end
    local a = inv(part, { "set_size", "setSize", "SetSize" }, inst, size)
    if a ~= nil then return end
    a = inv(part, { "set", "Set" }, inst, "Size", size)
    if a ~= nil then return end
    a = okc(function() inst.Size = size end)
    if a ~= nil then return end
    if not part_warned then
        print("[vector-fps] part size write API not found, hitbox expander idle")
        part_warned = true
    end
end

local FOV_SETTERS = {
    function(v)
        local f = mem(camera, "set_fov") or mem(camera, "setFov") or mem(camera, "SetFov")
        if type(f) == "function" then
            local r = okc(f, camera, v)
            if r == nil then r = okc(f, v) end
            if r ~= nil then return true end
        end
        return nil
    end,
    function(v)
        local r = okc(function() camera.FieldOfView = v end)
        if r ~= nil then return true end
        r = okc(function() camera.fov = v end)
        if r ~= nil then return true end
        r = okc(function() camera.FOV = v end)
        if r ~= nil then return true end
        return nil
    end,
    function(v)
        local f = mem(camera, "set_field_of_view") or mem(camera, "setFieldOfView")
            or mem(camera, "SetFieldOfView")
        if type(f) == "function" then
            local r = okc(f, camera, v)
            if r == nil then r = okc(f, v) end
            if r ~= nil then return true end
        end
        return nil
    end,
}

local fov_writer = nil
local fov_warned = false

local function apply_fov(v)
    if fov_writer == nil then
        for i = 1, #FOV_SETTERS do
            if FOV_SETTERS[i](v) then fov_writer = FOV_SETTERS[i]; return end
        end
        if not fov_warned then
            print("[vector-fps] camera FOV write API not found, custom FOV idle")
            fov_warned = true
        end
        return
    end
    fov_writer(v)
end

-- ----------------------------------------------------------------- esp ---

local ENEMY = { 1, 0.35, 0.35, 1 }
local VISIBLE_COL = { 1, 0.55, 0.2, 1 }

local function bounds(p)
    local b = okc(function() return p:get_bounds() end)
    if type(b) ~= "table" and type(b) ~= "userdata" then return nil end
    local x = mem(b, "x") or mem(b, "X")
    local y = mem(b, "y") or mem(b, "Y")
    local w = mem(b, "w") or mem(b, "W") or mem(b, "width")
    local h = mem(b, "h") or mem(b, "H") or mem(b, "height")
    local valid = mem(b, "valid")
    if valid == false then return nil end
    if type(x) ~= "number" or type(y) ~= "number"
        or type(w) ~= "number" or type(h) ~= "number" then return nil end
    if w <= 1 or h <= 1 then return nil end
    return x, y, w, h
end

local function draw_arrow(cx, cy, angle, R, col)
    local tx = cx + math.sin(angle) * R
    local ty = cy - math.cos(angle) * R
    local a1 = angle + 2.6
    local a2 = angle - 2.6
    local r = R * 0.62
    draw.line(tx, ty, cx + math.sin(a1) * r, cy - math.cos(a1) * r, col, 2.5)
    draw.line(tx, ty, cx + math.sin(a2) * r, cy - math.cos(a2) * r, col, 2.5)
end

local function cam_basis()
    local look = vxyz(camera.get_look_vector())
    local lx, ly, lz = 0, 0, -1
    if look then lx, ly, lz = look end
    local rx, ry, rz = -lz, 0, lx
    local rl = math.sqrt(rx * rx + ry * ry + rz * rz)
    if rl < 1e-4 then rx, ry, rz = 1, 0, 0
    else rx, ry, rz = rx / rl, ry / rl, rz / rl end
    local ux, uy, uz = ry * lz - rz * ly, rz * lx - rx * lz, rx * ly - ry * lx
    return lx, ly, lz, rx, ry, rz, ux, uy, uz
end

local function run_esp()
    if not menu.get("esp_on") then return end
    local lp = entity.get_local_player()
    if lp == nil then return end
    local mypos = mem(lp, "position") or mem(lp, "Position")
    local players = okc(entity.get_players)
    if type(players) ~= "table" then return end

    local sw, sh = utility.get_screen_size()
    local maxd = V.esp_maxd
    local hide_team = menu.get("esp_team")
    local vis_only = menu.get("esp_vis")
    local lx, ly, lz, rx, ry, rz, ux, uy, uz = cam_basis()
    local px, py, pz = vxyz(camera.get_position())
    local ox, oy = (sw or 0) * 0.5, (sh or 0) * 0.5
    local R = ((sw and sh) and math.min(sw, sh) or 600) * 0.42

    for i = 1, #players do
        local p = players[i]
        if mem(p, "is_local") ~= true and mem(p, "is_alive") == true then
            local pos = mem(p, "position") or mem(p, "Position")
            if pos ~= nil then
                local dist = (mypos ~= nil) and vdist(pos, mypos) or 0
                if dist <= maxd then
                    local teammate = hide_team and is_teammate(p) or false
                    local vis = (not vis_only) or is_visible(p)
                    if not teammate and vis then
                        local col = VISIBLE_COL
                        local bx, by, bw, bh = bounds(p)

                        if menu.get("esp_chams") then
                            okc(function()
                                draw.chams_player(p, col, { 1, 0, 0, 1 }, 0)
                            end)
                        end

                        if bx then
                            if menu.get("esp_box") then
                                okc(function() draw.box(bx, by, bw, bh, col, false, 0) end)
                            end
                            if menu.get("esp_corner") then
                                okc(function() draw.corner_box(bx, by, bw, bh, col) end)
                            end
                            if menu.get("esp_hp") then
                                local hp = mem(p, "health") or 0
                                local mhp = mem(p, "max_health") or 100
                                if mhp <= 0 then mhp = 100 end
                                okc(function()
                                    draw.health_bar(bx - 7, by, bh, hp, mhp)
                                end)
                            end
                            if menu.get("esp_name") then
                                draw.text(bx, by - 15, tostring(mem(p, "name") or "?"), col, 12)
                            end
                            if menu.get("esp_dist") then
                                draw.text(bx, by + bh + 3,
                                    string.format("%.0fm", dist), { 1, 1, 1, 0.75 }, 11)
                            end
                            if menu.get("esp_snap") then
                                draw.line(ox, sh, bx + bw * 0.5, by + bh, col, 1.5)
                            end
                        end

                        if menu.get("esp_skel") then
                            local m = bone_map(p)
                            if m then
                                for b = 1, #BONE_PAIRS do
                                    local a1 = m[BONE_PAIRS[b][1]]
                                    local a2 = m[BONE_PAIRS[b][2]]
                                    if a1 and a2 then
                                        draw.line(a1.x, a1.y, a2.x, a2.y,
                                            a1.vis and a2.vis and col or { 0.6, 0.6, 0.6, 0.6 }, 1.5)
                                    end
                                end
                            end
                        end

                        if menu.get("esp_arrow") then
                            local hx, hy, hz = vxyz(mem(p, "head_position") or pos)
                            local sx, sy, on = utility.world_to_screen(hx, hy, hz)
                            if not (on and sx) and px then
                                local dx, dy, dz = hx - px, hy - py, hz - pz
                                local fwd = dx * lx + dy * ly + dz * lz
                                local side = dx * rx + dy * ry + dz * rz
                                local vert = dx * ux + dy * uy + dz * uz
                                if fwd < 0 then vert = -vert end
                                local angle = math.atan2(side, vert)
                                draw_arrow(ox, oy, angle, R, { 1, 0.4, 0.1, 0.9 })
                            end
                        end
                    end
                end
            end
        end
    end
end

-- --------------------------------------------------------- silent aim ---

local hook_on = false

local function pick_target()
    local lp = entity.get_local_player()
    if lp == nil then return nil end
    local mypos = mem(lp, "position") or mem(lp, "Position")
    local players = okc(entity.get_players)
    if type(players) ~= "table" then return nil end

    local cx, cy = screen_center()
    local fov2 = V.aim_fov * V.aim_fov
    local maxd = V.aim_dist
    local head_only = menu.get("aim_head")
    local team_chk = menu.get("aim_team")
    local vis_chk = menu.get("aim_vis")

    local best, best_d = nil, fov2
    for i = 1, #players do
        local p = players[i]
        if mem(p, "is_local") ~= true and mem(p, "is_alive") == true then
            local pos = head_only and (mem(p, "head_position") or mem(p, "position"))
                or mem(p, "position")
            if pos ~= nil then
                local dist = (mypos ~= nil) and vdist(pos, mypos) or 0
                if dist <= maxd and (not team_chk or not is_teammate(p)) then
                    local hx, hy, hz = vxyz(pos)
                    if hx then
                        local sx, sy, on = utility.world_to_screen(hx, hy, hz)
                        if on and sx then
                            local dx, dy = sx - cx, sy - cy
                            local d2 = dx * dx + dy * dy
                            if d2 <= best_d and ((not vis_chk) or is_visible(p)) then
                                best, best_d = p, d2
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

local function aim_update()
    local on = menu.get("aim_on")
    if not on then
        if hook_on then
            okc(raycast.disable_silent_hook)
            okc(raycast.stop_silent_tracking)
            hook_on = false
        end
        return
    end

    if not hook_on then
        local active = okc(raycast.is_silent_hook_active)
        if active ~= true then okc(raycast.enable_silent_hook) end
        hook_on = true
    end

    local t = pick_target()
    if t == nil then
        if menu.get("aim_lmb") then okc(raycast.stop_silent_tracking) end
        return
    end

    local tgt = menu.get("aim_head") and (mem(t, "head_position") or mem(t, "position"))
        or mem(t, "position")
    local ox, oy, oz = vxyz(camera.get_position())
    local tx, ty, tz = vxyz(tgt)
    if not ox or not tx then return end

    local dx, dy, dz = tx - ox, ty - oy, tz - oz
    local len = math.sqrt(dx * dx + dy * dy + dz * dz)
    if len < 1e-3 then return end
    local dir = vnew(dx / len, dy / len, dz / len)
    if dir == nil then return end
    local org = vnew(ox, oy, oz) or camera.get_position()

    if menu.get("aim_lmb") then
        okc(raycast.track_silent_target, org, dir, 0x01)
    else
        okc(raycast.set_silent_target, org, dir)
    end
end

-- --------------------------------------------------------------- misc ---

local function run_misc()
    if menu.get("misc_wm") then
        local fps = math.floor(utility.get_fps() or 0)
        draw.text(6, 6, string.format("VECTOR FPS | %s | place %d | %d FPS",
            GAME_NAME, MY_PLACE, fps), { 0.25, 0.75, 1, 0.85 }, 13)
    end

    if menu.get("misc_cross") then
        local cx, cy = screen_center()
        local s, g = 7, 3
        local col = { 0.2, 1, 0.4, 0.9 }
        draw.line(cx - s - g, cy, cx - g, cy, col, 2)
        draw.line(cx + g, cy, cx + s + g, cy, col, 2)
        draw.line(cx, cy - s - g, cx, cy - g, col, 2)
        draw.line(cx, cy + g, cx, cy + s + g, col, 2)
    end

    if menu.get("aim_fovc") and menu.get("aim_on") then
        local cx, cy = screen_center()
        draw.circle(cx, cy, V.aim_fov, { 1, 1, 1, 0.45 }, 48, 1.5)
    end

    if menu.get("misc_fov_on") then apply_fov(V.fov_val) end
end

-- ----------------------------------------------------------- hitbox ---

thread.create(function()
    if not menu.get("misc_hb_on") then return end
    local players = okc(entity.get_players)
    if type(players) ~= "table" then return end
    local s = V.hb_size
    local size = vnew(s, s, s)
    if size == nil then return end
    for i = 1, #players do
        local p = players[i]
        if mem(p, "is_local") ~= true and mem(p, "is_alive") == true then
            local ch = mem(p, "character") or mem(p, "Character")
            if ch ~= nil then
                for _, part_name in ipairs({ "Head", "UpperTorso", "Torso" }) do
                    local inst = inv(ch, { "find_first_child", "findFirstChild",
                        "FindFirstChild" }, part_name)
                    if inst ~= nil then part_set_size(inst, size) end
                end
            end
        end
    end
end, 500)

-- -------------------------------------------------------------- frame ---

function on_frame()
    local md = mouse_down()
    local mx, my = mouse_pos()

    run_misc()
    run_esp()
    aim_update()

    if menu.get("misc_valp") then draw_values(md, mx, my) end
end

print(string.format("[vector-fps] loaded | game: %s | place: %d", GAME_NAME, MY_PLACE))
