-- music.lua
-- Full music helper module for NovoLabs OS

local M = {}

-- ================= STATE =================
M.ui = {}
M.state = {
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
function M.play()
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

function M.pause()
    audio_pause()
end

function M.next()
    audio_next()
    M.state.currentSong = nil -- force refresh
end

function M.prev()
    audio_prev()
    M.state.currentSong = nil
end

-- ================= COVER =================
function M.updateCover()
    local song = audio_get_current()
    if not song then return end

    if song ~= M.state.currentSong then
        M.state.currentSong = song

        local cover = normalize(audio_get_cover())

        if cover then
            print("[music] cover:", cover)

            -- safest method (works on your LVGL binding)
            lv_obj_del(M.ui.img)

            M.ui.img = lv_img_create(M.ui.container)
            lv_obj_align(M.ui.img, LV.ALIGN_BOTTOM_MID, 0, -135)

            lv_img_set_src_sd(M.ui.img, cover)

            M.state.currentCover = cover
        end
    end
end

-- ================= UI =================
function M.updateSong()
    local song = audio_get_current()
    if song then
        lv_label_set_text(M.ui.songLabel, song)
    end
end

function M.updateTime()
    if audio_is_playing() then
        local pos = audio_get_position()
        local dur = audio_get_duration()

        if pos and dur then
            lv_label_set_text(M.ui.songPlayTime,
                formatTime(pos) .. " / " .. formatTime(dur))
        end
    end
end

-- ================= INIT =================
function M.init(container)
    M.ui.container = container

    -- AUDIO INIT
    audio_start()
    audio_build_playlist("/music")
    audio_set_volume(21)

    -- IMAGE
    M.ui.img = lv_img_create(container)
    lv_obj_align(M.ui.img, LV.ALIGN_BOTTOM_MID, 0, -135)

    -- SONG LABEL
    M.ui.songLabel = lv_label_create(container)
    lv_label_set_text(M.ui.songLabel, "No song playing")
    lv_obj_align(M.ui.songLabel, LV.ALIGN_BOTTOM_LEFT, 15, -100)

    -- TIME LABEL
    M.ui.songPlayTime = lv_label_create(container)
    lv_label_set_text(M.ui.songPlayTime, "00:00 / 00:00")
    lv_obj_set_style_text_color(M.ui.songPlayTime, 0x808080, LV.PART_MAIN)
    lv_obj_align(M.ui.songPlayTime, LV.ALIGN_BOTTOM_LEFT, 15, -80)

    -- PANEL
    local panel = lv_obj_create(container)
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
    local play = createBtn(">")
    local pause = createBtn("||")
    local next = createBtn(">>")

    -- EVENTS
    lv_obj_add_event_cb(play, function() M.play() end, LV_EVENT_CLICKED)
    lv_obj_add_event_cb(pause, function() M.pause() end, LV_EVENT_CLICKED)
    lv_obj_add_event_cb(next, function() M.next() end, LV_EVENT_CLICKED)
    lv_obj_add_event_cb(back, function() M.prev() end, LV_EVENT_CLICKED)
end

-- ================= TICK =================
function M.tick()
    M.updateSong()
    M.updateTime()
    M.updateCover()
end

return M
