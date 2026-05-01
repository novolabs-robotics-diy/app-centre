-- Music Player (fixed for NovoLabs OS runtime)

local screen = lv_scr_act()

ui = {}

function on_init()
    -- Root container (IMPORTANT)
    ui.container = lv_obj_create(screen)
    lv_obj_set_size(ui.container, 320, 480)
    lv_obj_set_style_bg_color(ui.container, 0x000000, LV.PART_MAIN)
    lv_obj_set_style_border_width(ui.container, 0, LV.PART_MAIN)
    lv_obj_set_style_pad_all(ui.container, 0, LV.PART_MAIN)

    -- Start audio
    audio_start()
    audio_build_playlist("/music")
    audio_set_volume(21)

    -- Cover Image
    ui.img = lv_img_create(ui.container)
    -- lv_img_set_src_sd(ui.img, "/apps/test_app/icon.png")
    lv_obj_align(ui.img, LV.ALIGN_BOTTOM_MID, 0, -135)

    -- Song Label
    ui.songLabel = lv_label_create(ui.container)
    lv_label_set_text(ui.songLabel, "No song playing")
    lv_obj_align(ui.songLabel, LV.ALIGN_BOTTOM_MID, 0, -100)

    -- Playtime
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
    lv_obj_set_flex_align(ui.panel, LV.FLEX_ALIGN_SPACE_BETWEEN, LV.FLEX_ALIGN_START, LV.FLEX_ALIGN_CENTER)
    lv_obj_set_style_radius(ui.panel, 100, LV.PART_MAIN)

    -- Helper
    local function createBtn(txt)
        local btn = lv_btn_create(ui.panel)
        lv_obj_set_size(btn, 50, 50)
        lv_obj_set_style_bg_color(btn, 0x202020, LV_PART_MAIN)
        lv_obj_set_style_radius(btn, 100, LV_PART_MAIN)

        local lbl = lv_label_create(btn)
        lv_label_set_text(lbl, txt)
        lv_obj_center(lbl)

        return btn
    end

    -- Buttons
    ui.backwardBtn = createBtn("Back")
    ui.playBtn     = createBtn("Play")
    ui.pauseBtn    = createBtn("Pause")
    ui.forwardBtn  = createBtn("Next")

    -- Events
    lv_obj_add_event_cb(ui.playBtn, function()
        if not audio_is_playing() then
            local list = audio_get_playlist()
            if list and list[1] then
                audio_play(list[1])
            end
        else
            audio_resume()
        end
        canvas_reset()
        updateUI()
    end, LV_EVENT_CLICKED)

    lv_obj_add_event_cb(ui.pauseBtn, function()
        audio_pause()
    end, LV_EVENT_CLICKED)

    lv_obj_add_event_cb(ui.forwardBtn, function()
        audio_next()
        canvas_reset()
        updateUI()
    end, LV_EVENT_CLICKED)

    lv_obj_add_event_cb(ui.backwardBtn, function()
        audio_prev()
        canvas_reset()
        updateUI()
    end, LV_EVENT_CLICKED)

    return true
end

-- ===== LOGIC =====

g_cover_drawn = false

function canvas_reset()
    g_cover_drawn = false
end

function updateUI()
    -- Update song title
    local currentSong = audio_get_current()
    if currentSong then
        lv_label_set_text(ui.songLabel, currentSong)
    end

    -- Update cover image
    local coverPath = audio_get_cover()

    if coverPath then
        -- normalize path
        if not string.find(coverPath, "^/") then
            coverPath = "/" .. coverPath
        end

        -- only update if changed
        if ui.currentCover ~= coverPath then
            print("Updating cover:", coverPath)

            local ok = lv_img_set_src_sd(ui.img, coverPath)

            if ok ~= false then
                ui.currentCover = coverPath
            else
                print("Failed to load cover")
            end
        end
    end
end

local function formatTime(ms)
    local sec = ms // 1000
    local min = sec // 60
    sec = sec % 60
    return string.format("%d:%02d", min, sec)
end

function on_tick()
    -- update playtime
    if audio_is_playing() then
        local pos = audio_get_position()
        local dur = audio_get_duration()
        if pos and dur then
            lv_label_set_text(ui.songPlayTime,
                formatTime(pos) .. " / " .. formatTime(dur))
        end
    end

    -- detect song change
    local current = audio_get_current()
    if current ~= ui.lastSong then
        ui.lastSong = current
        updateUI()
    end
end

function on_destroy()
    os_log("Music player closed")
end
