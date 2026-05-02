-- Music Player (FIXED - NovoLabs OS runtime compatible)

local screen = lv_scr_act()

ui = {}
state = {
    lastSong = nil,
    currentCover = nil
}

-- ================= INIT =================

function on_init()

    ui.container = lv_obj_create(screen)
    lv_obj_set_size(ui.container, 320, 480)
    lv_obj_set_style_bg_color(ui.container, 0x000000, LV.PART_MAIN)
    lv_obj_set_style_border_width(ui.container, 0, LV.PART_MAIN)
    lv_obj_set_style_pad_all(ui.container, 0, LV.PART_MAIN)

    audio_start()
    audio_build_playlist("/music")
    audio_set_volume(21)

    -- Cover
    ui.img = lv_img_create(ui.container)
    lv_obj_align(ui.img, LV.ALIGN_BOTTOM_MID, 0, -135)
    lv_img_set_src_sd(ui.img, "/music/covers/default.png")

    -- Song label
    ui.songLabel = lv_label_create(ui.container)
    lv_label_set_text(ui.songLabel, "No song playing")
    lv_obj_align(ui.songLabel, LV.ALIGN_BOTTOM_LEFT, 0, -100)
    lv_obj_set_style_text_font(ui.songLabel, LV.FONT_NORMAL, LV.PART_MAIN)

    -- Time
    ui.songPlayTime = lv_label_create(ui.container)
    lv_label_set_text(ui.songPlayTime, "00:00 / 00:00")
    lv_obj_set_style_text_color(ui.songPlayTime, 0x808080, LV.PART_MAIN)
    lv_obj_align(ui.songPlayTime, LV.ALIGN_BOTTOM_LEFT, 15, -80)

    -- Panel
    ui.panel = lv_obj_create(ui.container)
    lv_obj_set_size(ui.panel, 290, 60)
    lv_obj_align(ui.panel, LV.ALIGN_BOTTOM_MID, 0, -15)
    lv_obj_set_style_bg_color(ui.panel, 0x101010, LV.PART_MAIN)
    lv_obj_set_style_border_color(ui.panel, 0x202020, LV.PART_MAIN)
    lv_obj_clear_flag(ui.panel, LV.FLAG_SCROLLABLE)
    lv_obj_set_flex_flow(ui.panel, LV.FLEX_FLOW_ROW)
    lv_obj_set_flex_align(ui.panel,
        LV.FLEX_ALIGN_SPACE_BETWEEN,
        LV.FLEX_ALIGN_START,
        LV.FLEX_ALIGN_CENTER)
    lv_obj_set_style_radius(ui.panel, 100, LV.PART_MAIN)

    -- Button factory
    local function createBtn(txt)
        local btn = lv_btn_create(ui.panel)
        lv_obj_set_size(btn, 50, 50)
        lv_obj_set_style_bg_color(btn, 0x202020, LV.PART_MAIN)
        lv_obj_set_style_radius(btn, 100, LV.PART_MAIN)

        local lbl = lv_label_create(btn)
        lv_label_set_text(lbl, txt)
        lv_obj_center(lbl)

        return btn
    end

    -- Buttons (UNCHANGED UI)
    ui.backwardBtn = createBtn("Back")
    ui.playBtn     = createBtn("Play")
    ui.pauseBtn    = createBtn("Pause")
    ui.forwardBtn  = createBtn("Next")

    -- ================= FIXED EVENTS =================

    lv_obj_add_event_cb(ui.playBtn, function()
        audio_play()
    end, LV_EVENT_CLICKED)

    lv_obj_add_event_cb(ui.pauseBtn, function()
        audio_pause()
    end, LV_EVENT_CLICKED)

    lv_obj_add_event_cb(ui.forwardBtn, function()
        audio_next()
    end, LV_EVENT_CLICKED)

    lv_obj_add_event_cb(ui.backwardBtn, function()
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

-- ================= UI UPDATE =================

local function updateCover()

    local cover = audio_get_cover()
    if not cover then
        cover = "/music/covers/default.png"
    end

    if not string.find(cover, "^/") then
        cover = "/" .. cover
    end

    if state.currentCover == cover then return end
    state.currentCover = cover

    print("[music] cover -> " .. cover)

    lv_img_set_src_sd(ui.img, cover)
    lv_obj_align(ui.img, LV.ALIGN_BOTTOM_MID, 0, -135)
end

local function updateSong()
    local list = audio_get_playlist()
    if not list then return end

    -- fallback: show first playing track metadata
    local name = "Playing..."

    if list[1] and list[1].title then
        name = list[1].title
    elseif list[1] and list[1].file then
        name = string.match(list[1].file, "([^/]+)%.%w+$") or list[1].file
    end

    lv_label_set_text(ui.songLabel, name)
end

-- ================= TICK =================

function on_tick()

    if audio_is_playing() then
        local pos = audio_get_position()
        local dur = audio_get_duration()

        if pos and dur then
            lv_label_set_text(ui.songPlayTime,
                formatTime(pos) .. " / " .. formatTime(dur))
        end
    end

    updateSong()
    updateCover()
end

-- ================= DESTROY =================

function on_destroy()
    audio_stop()
end
