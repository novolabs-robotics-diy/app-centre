-- Music Player (NovoLabs OS v3 FIXED)

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
    lv_obj_set_style_bg_color(ui.container, 0x000000, LV_PART_MAIN)
    lv_obj_set_style_border_width(ui.container, 0, LV_PART_MAIN)
    lv_obj_set_style_pad_all(ui.container, 0, LV_PART_MAIN)

    audio_start()
    audio_load_playlist()
    audio_set_volume(21)

    ui.img = lv_img_create(ui.container)
    lv_img_set_src_sd(ui.img, "")
    lv_img_set_src_sd(ui.img, "/music/covers/default.png")
    lv_obj_align(ui.img, LV.ALIGN_BOTTOM_MID, 0, -155)

    ui.songLabel = lv_label_create(ui.container)
    lv_label_set_text(ui.songLabel, "Loading...")
    lv_obj_align(ui.songLabel, LV.ALIGN_BOTTOM_LEFT, 15, -110)

    ui.songPlayTime = lv_label_create(ui.container)
    lv_label_set_text(ui.songPlayTime, "00:00 / 00:00")
    lv_obj_align(ui.songPlayTime, LV.ALIGN_BOTTOM_LEFT, 15, -85)

    -- PANEL
    ui.panel = lv_obj_create(ui.container)
    lv_obj_set_size(ui.panel, 290, 60)
    lv_obj_align(ui.panel, LV.ALIGN_BOTTOM_MID, 0, -15)
    lv_obj_set_style_bg_color(ui.panel, 0x101010, LV_PART_MAIN)
    lv_obj_set_style_radius(ui.panel, 100, LV_PART_MAIN)
    lv_obj_set_style_border_width(ui.panel, 0, LV_PART_MAIN)
    lv_obj_clear_flag(ui.panel, LV.FLAG_SCROLLABLE)

    lv_obj_set_flex_flow(ui.panel, LV.FLEX_FLOW_ROW)
    lv_obj_set_flex_align(ui.panel,
        LV.FLEX_ALIGN_SPACE_BETWEEN,
        LV.FLEX_ALIGN_CENTER,
        LV.FLEX_ALIGN_CENTER)

    -- FIXED BUTTONS
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

    -- EVENTS (NEW API ONLY)

    lv_obj_add_event_cb(ui.btnPlay, function()
        audio_play()
    end, LV_EVENT_CLICKED)

    lv_obj_add_event_cb(ui.btnPause, function()
        audio_pause()
    end, LV_EVENT_CLICKED)

    lv_obj_add_event_cb(ui.btnNext, function()
        audio_next()
    end, LV_EVENT_CLICKED)

    lv_obj_add_event_cb(ui.btnPrev, function()
        audio_prev()
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

-- ================= UI =================

function on_tick()

    local list = audio_get_playlist()
    if not list or #list == 0 then return end

    local t = list[state.index]

    if t then
        lv_label_set_text(ui.songLabel, t.title or t.file)
    end

    if audio_is_playing() then
        local pos = audio_get_position()
        local dur = audio_get_duration()

        lv_label_set_text(ui.songPlayTime,
            formatTime(pos) .. " / " .. formatTime(dur))
    end

    if t and t.cover and state.currentCover ~= t.cover then
        state.currentCover = t.cover
        os_log("[music] loading cover -> " .. tostring(cover))
        lv_img_set_src_sd(ui.img, "")
        lv_img_set_src_sd(ui.img, t.cover)
        lv_obj_align(ui.img, LV.ALIGN_BOTTOM_MID, 0, -155)
    else
        lv_img_set_src_sd(ui.img, "")
        lv_img_set_src_sd(ui.img, "/music/covers/default.png")
        lv_obj_align(ui.img, LV.ALIGN_BOTTOM_MID, 0, -155)
    end
end

function on_destroy()
    audio_stop()
end
