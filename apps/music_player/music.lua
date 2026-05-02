-- Music App (NovoLabs OS v2.0 FIXED)

local screen = lv_scr_act()

ui = {}

state = {
    playlist = {},
    index = 1,
    currentCover = nil
}

-- ================= UTILS =================

local function normalize(path)
    if not path then return nil end
    if not string.find(path, "^/") then
        return "/" .. path
    end
    return path
end

local function formatTime(ms)
    if not ms then return "0:00" end
    local sec = ms // 1000
    local min = sec // 60
    sec = sec % 60
    return string.format("%d:%02d", min, sec)
end

-- ================= AUDIO CONTROL =================

local function play()
    audio_play()
end

local function pause()
    audio_pause()
end

local function next()
    audio_forward()
    state.index = state.index + 1
    if state.index > #state.playlist then
        state.index = 1
    end
end

local function prev()
    audio_backward()
    state.index = state.index - 1
    if state.index < 1 then
        state.index = #state.playlist
    end
end

-- ================= PLAYLIST CACHE =================

local function refreshPlaylist()
    local list = audio_get_playlist()
    if not list then return end

    state.playlist = list

    if state.index < 1 then state.index = 1 end
    if state.index > #list then state.index = 1 end
end

local function getCurrent()
    return state.playlist[state.index]
end

-- ================= UI UPDATE =================

local function updateSong()
    local song = getCurrent()
    if not song then return end

    local name = song.title or song.file or "Unknown"
    lv_label_set_text(ui.songLabel, name)
end

local function updateTime()
    local pos = audio_get_position()
    local dur = audio_get_duration()

    lv_label_set_text(ui.timeLabel,
        formatTime(pos) .. " / " .. formatTime(dur))
end

local function updateCover()

    local song = getCurrent()
    if not song then return end

    local cover = song.cover or "/music/covers/default.png"
    cover = normalize(cover)

    if state.currentCover == cover then return end
    state.currentCover = cover

    os_log("[music] cover -> " .. cover)

    -- IMPORTANT FIX:
    -- no lv_timer_create, no async delay (that was causing black image)
    lv_img_set_src_sd(ui.img, cover)
    lv_obj_center(ui.img)
end

-- ================= INIT =================

function on_init()

    ui.container = lv_obj_create(screen)
    lv_obj_set_size(ui.container, 320, 480)
    lv_obj_set_style_bg_color(ui.container, 0x000000, LV.PART_MAIN)
    lv_obj_clear_flag(ui.container, LV.FLAG_SCROLLABLE)

    ui.imgBox = lv_obj_create(ui.container)
    lv_obj_set_size(ui.imgBox, 200, 200)
    lv_obj_align(ui.imgBox, LV.ALIGN_TOP_MID, 0, 40)
    lv_obj_set_style_bg_color(ui.imgBox, 0x111111, LV.PART_MAIN)
    lv_obj_set_style_radius(ui.imgBox, 12, LV.PART_MAIN)

    ui.img = lv_img_create(ui.imgBox)
    lv_obj_center(ui.img)
    lv_img_set_src_sd(ui.img, "/music/covers/default.png")

    ui.songLabel = lv_label_create(ui.container)
    lv_obj_align(ui.songLabel, LV.ALIGN_TOP_MID, 0, 260)
    lv_label_set_text(ui.songLabel, "Loading...")

    ui.timeLabel = lv_label_create(ui.container)
    lv_obj_align(ui.timeLabel, LV.ALIGN_TOP_MID, 0, 290)
    lv_label_set_text(ui.timeLabel, "0:00 / 0:00")

    -- Controls
    local panel = lv_obj_create(ui.container)
    lv_obj_set_size(panel, 290, 70)
    lv_obj_align(panel, LV.ALIGN_BOTTOM_MID, 0, -15)

    local function btn(txt, cb)
        local b = lv_btn_create(panel)
        lv_obj_set_size(b, 52, 52)
        local l = lv_label_create(b)
        lv_label_set_text(l, txt)
        lv_obj_center(l)
        lv_obj_add_event_cb(b, cb, LV_EVENT_CLICKED)
        return b
    end

    btn("<<", function()
        prev()
        refreshPlaylist()
    end)

    btn(">", function()
        play()
        refreshPlaylist()
    end)

    btn("||", pause)

    btn(">>", function()
        next()
        refreshPlaylist()
    end)

    -- AUDIO INIT
    audio_start()
    audio_build_playlist("/music")
    audio_set_volume(18)

    refreshPlaylist()

    return true
end

-- ================= TICK =================

function on_tick()
    refreshPlaylist()
    updateSong()
    updateTime()
    updateCover()
end

-- ================= CLEANUP =================

function on_destroy()
    audio_stop()
end
