-- Music App (NovoLabs OS v2.0)

local screen = lv_scr_act()

ui = {}
state = {
    currentSong = nil,
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
    audio_play()
end

local function pause()
    audio_pause()
end

local function next()
    audio_forward()
    state.currentSong = nil  -- force UI refresh on next tick
end

local function prev()
    audio_backward()
    state.currentSong = nil
end

-- ================= UI UPDATE =================
local function updateSong()
    local song = audio_get_current()
    if song then
        -- Strip path, show just filename without extension
        local name = string.match(song, "([^/]+)%.%w+$") or song
        lv_label_set_text(ui.songLabel, name)
    end
end

local function updateTime()
    local pos = audio_get_position()
    local dur = audio_get_duration()
    if pos and dur and dur > 0 then
        lv_label_set_text(ui.timeLabel,
            formatTime(pos) .. " / " .. formatTime(dur))
    end
end

local function updateCover()
    local song = audio_get_current()
    if not song then return end
    if song == state.currentSong then return end

    state.currentSong = song

    local cover = normalize(audio_get_cover())
    local path = cover or "/music/covers/default.png"

    os_log("[music] heap before cover: " .. tostring(os_free_heap()))
    lv_img_set_src_sd(ui.img, path)

    -- FIX: lv_img_set_src in LVGL 8 auto-resizes the widget to the PNG's
    -- actual pixel dimensions, overwriting any explicit size set earlier.
    -- Re-apply the size every time after swapping src.
    lv_obj_set_size(ui.img, 200, 200)
    lv_obj_align(ui.img, LV.ALIGN_TOP_MID, 0, 40)

    os_log("[music] heap after cover: " .. tostring(os_free_heap()))
end

-- ================= INIT =================
function on_init()
    -- Root container
    ui.container = lv_obj_create(screen)
    lv_obj_set_size(ui.container, 320, 480)
    lv_obj_set_style_bg_color(ui.container, 0x000000, LV.PART_MAIN)
    lv_obj_set_style_border_width(ui.container, 0, LV.PART_MAIN)
    lv_obj_set_style_pad_all(ui.container, 0, LV.PART_MAIN)
    lv_obj_clear_flag(ui.container, LV.FLAG_SCROLLABLE)

    -- Cover image
    -- FIX: Set an explicit pixel size (135×135).
    -- LV_SIZE_CONTENT on a file-source image in LVGL 8 resolves to 0×0 because
    -- the file hasn't been decoded yet when the size is applied.
    -- Set the actual cover dimensions explicitly instead.
    ui.img = lv_img_create(ui.container)
    lv_obj_set_size(ui.img, 200, 200)
    lv_obj_align(ui.img, LV.ALIGN_TOP_MID, 0, 40)
    lv_img_set_src_sd(ui.img, "/music/covers/default.png")

    -- Song label
    ui.songLabel = lv_label_create(ui.container)
    lv_label_set_text(ui.songLabel, "No song playing")
    lv_obj_align(ui.songLabel, LV.ALIGN_TOP_MID, 0, 260)
    lv_obj_set_style_text_font(ui.songLabel, LV.FONT_NORMAL, LV.PART_MAIN)
    lv_obj_set_style_text_color(ui.songLabel, 0xFFFFFF, LV.PART_MAIN)

    -- Time label
    ui.timeLabel = lv_label_create(ui.container)
    lv_label_set_text(ui.timeLabel, "0:00 / 0:00")
    lv_obj_align(ui.timeLabel, LV.ALIGN_TOP_MID, 0, 290)
    lv_obj_set_style_text_color(ui.timeLabel, 0x808080, LV.PART_MAIN)
    lv_obj_set_style_text_font(ui.timeLabel, LV.FONT_SMALL, LV.PART_MAIN)

    -- Controls panel
    local panel = lv_obj_create(ui.container)
    lv_obj_set_size(panel, 290, 70)
    lv_obj_align(panel, LV.ALIGN_BOTTOM_MID, 0, -15)
    lv_obj_set_style_bg_color(panel, 0x101010, LV.PART_MAIN)
    lv_obj_set_style_border_color(panel, 0x202020, LV.PART_MAIN)
    lv_obj_set_style_border_width(panel, 1, LV.PART_MAIN)
    lv_obj_set_style_radius(panel, 35, LV.PART_MAIN)
    lv_obj_clear_flag(panel, LV.FLAG_SCROLLABLE)
    lv_obj_set_flex_flow(panel, LV.FLEX_FLOW_ROW)
    lv_obj_set_flex_align(panel, LV.FLEX_ALIGN_SPACE_EVENLY, LV.FLEX_ALIGN_CENTER, LV.FLEX_ALIGN_CENTER)
    lv_obj_set_style_pad_all(panel, 8, LV.PART_MAIN)

    local function createBtn(txt)
        local btn = lv_btn_create(panel)
        lv_obj_set_size(btn, 52, 52)
        lv_obj_set_style_bg_color(btn, 0x202020, LV.PART_MAIN)
        lv_obj_set_style_radius(btn, 26, LV.PART_MAIN)
        lv_obj_set_style_border_width(btn, 0, LV.PART_MAIN)
        local lbl = lv_label_create(btn)
        lv_label_set_text(lbl, txt)
        lv_obj_center(lbl)
        return btn
    end

    local btnPrev = createBtn("<<")
    local btnPlay = createBtn(">")
    local btnPause = createBtn("||")
    local btnNext = createBtn(">>")

    lv_obj_add_event_cb(btnPlay,  function() play()  end, LV_EVENT_CLICKED)
    lv_obj_add_event_cb(btnPause, function() pause() end, LV_EVENT_CLICKED)
    lv_obj_add_event_cb(btnNext,  function() next()  end, LV_EVENT_CLICKED)
    lv_obj_add_event_cb(btnPrev,  function() prev()  end, LV_EVENT_CLICKED)

    -- Start audio
    audio_start()
    audio_build_playlist("/music")
    audio_set_volume(18)
    audio_play()

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
    audio_stop()
    os_log("Music app closed")
end
