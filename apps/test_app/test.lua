-- NovoLabs OS v2.0 App Template
-- Lifecycle: on_init → [on_tick loop] → on_destroy

local screen = lv_scr_act()
local label, btn, timer_handle

function on_init()
    -- Build UI inside the sandboxed ui_AppPanel
    local container = lv_obj_create(screen)
    lv_obj_set_size(container, 320, 480)
    lv_obj_set_style_bg_color(container, 0x0D0D0D, LV_PART_MAIN)
    lv_obj_set_style_border_width(container, 0, LV_PART_MAIN)
    lv_obj_set_style_radius(container, 0)
    lv_obj_set_style_pad_left(container, 15, LV_PART_MAIN)
    lv_obj_set_style_pad_right(container, 15, LV_PART_MAIN)
    lv_obj_set_style_pad_top(container, 40, LV_PART_MAIN)
    lv_obj_set_style_pad_bottom(container, 0, LV_PART_MAIN)
    lv_obj_set_flex_flow(container, LV_FLEX_FLOW_COLUMN)
    lv_obj_set_style_pad_row(container, 14, LV_PART_MAIN)
    lv_obj_clear_flag(container, LV_OBJ_FLAG_SCROLLABLE)

    -- Title
    label = lv_label_create(container)
    lv_label_set_text(label, "Hello NovoLabs!")
    lv_obj_set_text_font(label, "font_montserrat_22", LV_PART_MAIN)
    lv_obj_set_style_text_color(label, 0xFFFFFF, LV_PART_MAIN)

    -- Battery & time
    local info = lv_label_create(container)
    local t = rtc_get_time()
    lv_label_set_text(info, string.format(
        "%s  Bat. Level %d%%", t.iso, battery_percent()))
    lv_obj_set_style_text_color(info, 0x909090, LV_PART_MAIN)
    lv_obj_set_text_font(info, "font_montserrat_14", LV_PART_MAIN)

    -- IMU readout
    local imu_label = lv_label_create(container)
    local imu = imu_get_accel()
    if imu then
        lv_label_set_text(imu_label, string.format(
            "Accel: x=%.2f y=%.2f z=%.2f", imu.x, imu.y, imu.z))
    end
    lv_obj_set_style_text_color(imu_label, 0x60AAFF, LV_PART_MAIN)

    -- NVS counter (persists across sessions)
    local count = nvs_get_int("open_count", 0) + 1
    nvs_set_int("open_count", count)
    local cnt_label = lv_label_create(container)
    lv_label_set_text(cnt_label, "Opened " .. tostring(count) .. " times")
    lv_obj_set_style_text_color(cnt_label, 0xFFA040, LV_PART_MAIN)

    -- Button with event
    btn = lv_btn_create(container)
    lv_obj_set_size(btn, 200, 40)
    lv_obj_set_style_radius(btn, 10, LV_PART_MAIN)
    lv_obj_set_style_bg_color(btn, 0x2979FF, LV_PART_MAIN)

    local btn_lbl = lv_label_create(btn)
    lv_label_set_text(btn_lbl, LV_SYM_WIFI .. "  Check WiFi")
    lv_obj_center(btn_lbl)

    lv_obj_add_event_cb(btn, function(obj, code)
        local status = wifi_connected() and
            ("Connected to " .. wifi_ssid() .. "  " .. wifi_ip()) or
            "Not connected"
        lv_label_set_text(label, status)
    end, LV.EVENT_CLICKED)

    -- SD image example
    local img = lv_img_create(container)
    lv_img_set_src_sd(img, "/apps/test_app/icon.png")
    lv_obj_set_size(img, LV_SIZE_CONTENT, LV_SIZE_CONTENT)

    return true  -- on_init must return true to continue
end

-- Called every 50ms
function on_tick()
    -- Update clock label periodically (every ~1s via counter)
    -- or use lv_timer_create for fine control
end

function on_destroy()
    os_log("App closed!")
    -- Cleanup: LVGL objects auto-deleted when AppPanel is cleaned
end
