-- Music App (NovoLabs OS compatible)

local screen = lv_scr_act()

ui = {}
state = {
    currentSong = nil,
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
    local sec = ms // 1000
    local min = sec // 60
    sec = sec % 60
    return string.format("%d:%02d", min, sec)
end

-- ================= AUDIO CONTROL =================
local function play()
    if audio_is_playing() then return end

    local pos = audio_get_position()

    if pos and pos > 0 then
        audio_resume()
    else
        local list = audio_get_playlist()
        if list and list[1] then
            audio_play(list[1])
        end
    end
end

local function pause()
    audio_pause()
end

local function next()
    audio_next()
    state.currentSong = nil -- force UI refresh
end

local function prev()
    audio_prev()
    state.currentSong = nil
end

-- ================= UI UPDATE =================
local function updateSong()
    local song = audio_get_current()
    if song then
        lv_label_set_text(ui.songLabel, song)
    end
end

local function updateTime()
    if audio_is_playing() then
        local pos = audio_get_position()
        local dur = audio_get_duration()

        if pos and dur then
            lv_label_set_text(ui.songPlayTime,
                formatTime(pos) .. " / " .. formatTime(dur))
        end
    end
end

local function updateCover()
    local song = audio_get_current()
    if not song then return end

    if song ~= state.currentSong then
        state.currentSong = song

        local cover = normalize(audio_get_cover())

        if cover then
            os_log("[music] updating cover: " .. cover)

            -- force refresh (safe for your LVGL bindings)
            if ui.img then
                lv_obj_delete(ui.img)
            end

            ui.img = lv_img_create(ui.container)
            lv_obj_set_size(ui.img, LV.SIZE_CONTENT, LV.SIZE_CONTENT)
            lv_obj_align(ui.img, LV.ALIGN_BOTTOM_MID, 0, -135)

            lv_img_set_src_sd(ui.img, cover)

            state.currentCover = cover
        else
            os_log("[music] no cover returned")
        end
    end
end

-- ================= INIT =================
function on_init()
    -- ROOT CONTAINER
    ui.container = lv_obj_create(screen)
    lv_obj_set_size(ui.container, 320, 480)
    lv_obj_set_style_bg_color(ui.container, 0x000000, LV.PART_MAIN)
    lv_obj_set_style_border_width(ui.container, 0, LV.PART_MAIN)

    -- AUDIO INIT
    audio_start()
    audio_build_playlist("/music")
    audio_set_volume(21)

    -- COVER IMAGE
    ui.img = lv_img_create(ui.container)
    lv_obj_set_size(ui.img, LV.SIZE_CONTENT, LV.SIZE_CONTENT)
    lv_obj_align(ui.img, LV.ALIGN_BOTTOM_MID, 0, -135)

    -- SONG LABEL
    ui.songLabel = lv_label_create(ui.container)
    lv_label_set_text(ui.songLabel, "No song playing")
    lv_obj_align(ui.songLabel, LV.ALIGN_BOTTOM_MID, 0, -100)
    lv_obj_set_style_text_font(ui.songLabel, LV.FONT_NORMAL, LV.PART_MAIN)

    -- TIME LABEL
    ui.songPlayTime = lv_label_create(ui.container)
    lv_label_set_text(ui.songPlayTime, "00:00 / 00:00")
    lv_obj_set_style_text_color(ui.songPlayTime, 0x808080, LV.PART_MAIN)
    lv_obj_align(ui.songPlayTime, LV.ALIGN_BOTTOM_LEFT, 15, -80)

    -- PANEL
    local panel = lv_obj_create(ui.container)
    lv_obj_set_size(panel, 290, 60)
    lv_obj_align(panel, LV.ALIGN_BOTTOM_MID, 0, -15)
    lv_obj_set_style_bg_color(panel, 0x101010, LV.PART_MAIN)
    lv_obj_set_style_border_color(panel, 0x202020, LV.PART_MAIN)
    lv_obj_clear_flag(panel, LV.FLAG_SCROLLABLE)
    lv_obj_set_flex_flow(panel, LV.FLEX_FLOW_ROW)
    lv_obj_set_flex_align(panel, LV.FLEX_ALIGN_SPACE_BETWEEN, LV.FLEX_ALIGN_START, LV.FLEX_ALIGN_CENTER)
    lv_obj_set_style_radius(panel, 100, LV.PART_MAIN)

    local function createBtn(txt)
        local btn = lv_btn_create(panel)
        lv_obj_set_size(btn, 50, 50)
        lv_obj_set_style_bg_color(btn, 0x202020, LV.PART_MAIN)
        lv_obj_set_style_radius(btn, 100, LV.PART_MAIN)

        local lbl = lv_label_create(btn)
        lv_label_set_text(lbl, txt)
        lv_obj_center(lbl)

        return btn
    end

    local back = createBtn("<<")
    local playBtn = createBtn(">")
    local pauseBtn = createBtn("||")
    local nextBtn = createBtn(">>")

    -- EVENTS
    lv_obj_add_event_cb(playBtn, function() play() end, LV_EVENT_CLICKED)
    lv_obj_add_event_cb(pauseBtn, function() pause() end, LV_EVENT_CLICKED)
    lv_obj_add_event_cb(nextBtn, function() next() end, LV_EVENT_CLICKED)
    lv_obj_add_event_cb(back, function() prev() end, LV_EVENT_CLICKED)

    return true
end

-- ================= TICK =================
function on_tick()
    updateSong()
    updateTime()
    updateCover()
end

-- ================= DESTROY =================
function on_destroy()
    os_log("Music app closed")
end
