-- Music Player
-- Created by novolabs

local scr = lv_scr_act()

-- Start audio system and build playlist
audio_start()
audio_build_playlist("/music")
audio_set_volume(21)

-- Cover Image
local coverCanvas = lv_canvas_create(scr)
lv_obj_set_size(coverCanvas, 135, 135)  -- or LV_SIZE_CONTENT if you prefer
lv_obj_set_align(coverCanvas, LV_ALIGN_BOTTOM_MID)
lv_obj_set_pos(coverCanvas, 0, -135)
lv_obj_clear_flag(coverCanvas, LV_OBJ_FLAG_SCROLLABLE)

-- Song Label
local songLabel = lv_label_create(scr)
lv_obj_set_size(songLabel, 290, 21)
lv_label_set_text(songLabel, "No song playing")
lv_obj_set_align(songLabel, LV_ALIGN_BOTTOM_MID)
lv_obj_set_text_font(songLabel, "font_montserrat_18")
lv_obj_set_pos(songLabel, 0, -120)

-- Song playtime
local songPlayTime = lv_label_create(scr)
lv_label_set_text(songPlayTime, "00:00 / 00:00")
lv_obj_set_style_text_color(songPlayTime, lv_color_hex(0x808080), LV_PART_MAIN)
lv_obj_set_align(songPlayTime, LV_ALIGN_BOTTOM_LEFT)
lv_obj_set_pos(songPlayTime, 15, -100)

-- Media Panel
local panel = lv_obj_create(scr)
lv_obj_set_size(panel, 290, 60)
lv_obj_set_align(panel, LV_ALIGN_BOTTOM_MID)
lv_obj_set_pos(panel, 0, -15)
lv_obj_set_style_bg_color(panel, lv_color_hex(0x101010), LV_PART_MAIN)
lv_obj_set_style_border_color(panel, lv_color_hex(0x202020), LV_PART_MAIN)
lv_obj_clear_flag(panel, LV_OBJ_FLAG_SCROLLABLE)
lv_obj_set_flex_flow(panel, LV_FLEX_FLOW_ROW)
lv_obj_set_flex_align(panel, LV_FLEX_ALIGN_SPACE_BETWEEN, LV_FLEX_ALIGN_START, LV_FLEX_ALIGN_CENTER)
lv_obj_set_style_radius(panel, 100, LV_PART_MAIN)

-- Media Buttons
local backwardBtn = lv_btn_create(panel)
lv_obj_set_size(backwardBtn, 50, 50)
lv_obj_set_style_bg_color(backwardBtn, lv_color_hex(0x202020), LV_PART_MAIN)
lv_obj_set_style_radius(backwardBtn, 100, LV_PART_MAIN)
local playBtn = lv_btn_create(panel)
lv_obj_set_size(playBtn, 50, 50)
lv_obj_set_style_bg_color(playBtn, lv_color_hex(0x202020), LV_PART_MAIN)
lv_obj_set_style_radius(playBtn, 100, LV_PART_MAIN)
local pauseBtn = lv_btn_create(panel)
lv_obj_set_size(pauseBtn, 50, 50)
lv_obj_set_style_bg_color(pauseBtn, lv_color_hex(0x202020), LV_PART_MAIN)
lv_obj_set_style_radius(pauseBtn, 100, LV_PART_MAIN)
local fowardBtn = lv_btn_create(panel)
lv_obj_set_size(fowardBtn, 50, 50)
lv_obj_set_style_bg_color(fowardBtn, lv_color_hex(0x202020), LV_PART_MAIN)
lv_obj_set_style_radius(fowardBtn, 100, LV_PART_MAIN)

-- Labels for buttons
local function createBtnLabel(btn, txt)
    local lbl = lv_label_create(btn)
    lv_label_set_text(lbl, txt)
    lv_obj_set_align(lbl, LV_ALIGN_CENTER)
end

createBtnLabel(backwardBtn, "Backward")
createBtnLabel(playBtn, "Play")
createBtnLabel(pauseBtn, "Pause")
createBtnLabel(fowardBtn, "Foward")

-- Button events
lv_obj_add_event_cb(playBtn, function()
    if not audio_is_playing() then
        audio_play(audio_get_playlist()[1]) -- play first song if nothing playing
    else
        audio_resume()
    end
    canvas_reset()
    updateUI()
end, LV_EVENT_CLICKED)

lv_obj_add_event_cb(pauseBtn, function()
    audio_pause()
end, LV_EVENT_CLICKED)

lv_obj_add_event_cb(fowardBtn, function()
    audio_next()
end, LV_EVENT_CLICKED)

lv_obj_add_event_cb(backwardBtn, function()
    audio_prev()
end, LV_EVENT_CLICKED)

-- Update function (song label, time, cover)
function canvas_reset()
    g_cover_drawn = false  -- global Lua variable for tracking
end

-- Update UI function, called on song change or play
function updateUI()
    -- Update song label
    local currentSong = audio_get_current()
    if currentSong then
        lv_label_set_text(songLabel, currentSong)
    end

    -- Load cover image once per play
    local coverPath = audio_get_cover()
    if coverPath and not g_cover_drawn then
        if not string.find(coverPath, "^/") then
            coverPath = "/" .. coverPath
        end
        print("Loading cover:", coverPath)
        local success = canvas_load_image(coverCanvas, coverPath)
        if success then
            print("Cover drawn successfully!")
            g_cover_drawn = true
        else
            print("Failed to draw cover")
        end
    end
end

local function formatTime(ms)
    local sec = ms // 1000       -- integer division
    local min = sec // 60
    sec = sec % 60
    return string.format("%d:%02d", min, sec)
end

local function updatePlayTime()
    if audio_is_playing() then
        local pos = audio_get_position()
        local dur = audio_get_duration()
        lv_label_set_text(songPlayTime, formatTime(pos) .. " / " .. formatTime(dur))
    end
end

lv_timer_create(updatePlayTime, 1000, nil)
