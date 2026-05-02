-- Music Player (NovoLabs OS v3 - FULL METADATA SYSTEM)

local screen = lv_scr_act()

ui = {}

state = {
    playlist = {},
    index = 1,
    currentCover = nil
}

-- ================= INIT =================

function on_init()

    ui.container = lv_obj_create(screen)
    lv_obj_set_size(ui.container, 320, 480)
    lv_obj_set_style_bg_color(ui.container, 0x000000, LV.PART_MAIN)
    lv_obj_set_style_border_width(ui.container, 0, LV.PART_MAIN)
    lv_obj_set_style_pad_all(ui.container, 0, LV.PART_MAIN)

    -- AUDIO INIT
    audio_start()
    audio_build_playlist("/music")
    audio_set_volume(21)

    -- COVER
    ui.img = lv_img_create(ui.container)
    lv_obj_align(ui.img, LV.ALIGN_BOTTOM_MID, 0, -155)
    lv_img_set_src_sd(ui.img, "/music/covers/default.png")

    -- TITLE
    ui.songLabel = lv_label_create(ui.container)
    lv_label_set_text(ui.songLabel, "Loading...")
    lv_obj_align(ui.songLabel, LV.ALIGN_BOTTOM_LEFT, 15, -110)
    lv_obj_set_style_text_font(ui.songLabel, LV.FONT_NORMAL, LV.PART_MAIN)

    -- TIME
    ui.songPlayTime = lv_label_create(ui.container)
    lv_label_set_text(ui.songPlayTime, "00:00 / 00:00")
    lv_obj_align(ui.songPlayTime, LV.ALIGN_BOTTOM_LEFT, 15, -85)
    lv_obj_set_style_text_color(ui.songPlayTime, 0x808080, LV.PART_MAIN)

    -- PANEL  
    ui.panel = lv_obj_create(ui.container)
    lv_obj_set_size(ui.panel, 290, 60)
    lv_obj_align(ui.panel, LV.ALIGN_BOTTOM_MID, 0, -15)
    lv_obj_set_style_bg_color(ui.panel, 0x101010, LV.PART_MAIN)
    lv_obj_set_style_radius(ui.panel, 100, LV.PART_MAIN)
    lv_obj_set_style_border_color(ui.panel, 0x202020, LV.PART_MAIN)
    lv_obj_clear_flag(ui.panel, LV.FLAG_SCROLLABLE)
    lv_obj_set_flex_flow(ui.panel, LV.FLEX_FLOW_ROW)
    lv_obj_set_flex_align(ui.panel,
        LV.FLEX_ALIGN_SPACE_BETWEEN,
        LV.FLEX_ALIGN_CENTER,
        LV.FLEX_ALIGN_CENTER)

    -- BUTTONS
    local function btn(txt)
        local b = lv_btn_create(ui.panel)
        lv_obj_set_size(b, 50, 50)
        lv_obj_set_style_bg_color(b, 0x202020, LV_PART_MAIN)
        lv_obj_set_style_radius(b, 100, LV_PART_MAIN)

        local l = lv_label_create(b)
        lv_label_set_text(l, txt)
        lv_obj_center(l)
        return b
    end

    ui.btnPrev = btn("Back")
    ui.btnPlay = btn("Play")
    ui.btnPause = btn("Pause")
    ui.btnNext = btn("Next")

    -- ================= EVENTS =================

    lv_obj_add_event_cb(ui.btnPlay, function()
        audio_play()
    end, LV_EVENT_CLICKED)

    lv_obj_add_event_cb(ui.btnPause, function()
        audio_pause()
    end, LV_EVENT_CLICKED)

    lv_obj_add_event_cb(ui.btnNext, function()
        audio_next()
        state.index = state.index + 1
    end, LV_EVENT_CLICKED)

    lv_obj_add_event_cb(ui.btnPrev, function()
        audio_prev()
        state.index = state.index - 1
    end, LV_EVENT_CLICKED)

    return true
end

-- ================= HELPERS =================

local function formatTime(ms)
    if not ms then return "00:00" end
    local sec = ms // 1000
    local min = sec // 60
    sec = sec % 60
    return string.format("%d:%02d", min, sec)
end

-- ================= SYNC PLAYLIST =================

local function syncPlaylist()
    local list = audio_get_playlist()
    if not list or #list == 0 then return end

    state.playlist = list

    if state.index < 1 then state.index = 1 end
    if state.index > #list then state.index = 1 end
end

local function current()
    return state.playlist[state.index]
end

-- ================= UI =================

local function updateSong()

    local t = current()
    if not t then return end

    local title = t.title or t.file or "Unknown"
    lv_label_set_text(ui.songLabel, title)
end

local function updateCover()

    local t = current()
    if not t then return end

    local cover = t.cover or "/music/covers/default.png"

    if state.currentCover == cover then return end
    state.currentCover = cover

    os_log("[music] cover -> " .. cover)

    lv_img_set_src_sd(ui.img, cover)
    lv_obj_align(ui.img, LV.ALIGN_BOTTOM_MID, 0, -135)
end

-- ================= TICK =================

function on_tick()

    syncPlaylist()

    if audio_is_playing() then
        local pos = audio_get_position()
        local dur = audio_get_duration()

        lv_label_set_text(ui.songPlayTime,
            formatTime(pos) .. " / " .. formatTime(dur))
    end

    updateSong()
    updateCover()
end

-- ================= CLEAN =================

function on_destroy()
    audio_stop()
end
