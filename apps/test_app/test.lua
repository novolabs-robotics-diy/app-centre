-- NovoLabs OS v2.0 App Template
-- Lifecycle: on_init → [on_tick loop] → on_destroy

local screen = lv_scr_act()
local label, btn, timer_handle

function on_init()
    -- Build UI inside the sandboxed ui_AppPanel
    local container = lv_obj_create(screen)
    lv_obj_set_size(container, 320, 480)
    lv_obj_set_style_bg_color(container, 0x0D0D0D, LV.PART_MAIN)
    lv_obj_set_style_bg_opa(container, 255, LV.PART_MAIN)
    lv_obj_set_style_border_width(container, 0, LV.PART_MAIN)
    lv_obj_set_style_pad_all(container, 20, LV.PART_MAIN)
    lv_obj_set_flex_flow(container, LV.FLEX_FLOW_COLUMN)
    lv_obj_set_style_pad_row(container, 14, LV.PART_MAIN)
    lv_obj_clear_flag(container, LV.FLAG_SCROLLABLE)

    -- Title
    label = lv_label_create(container)
    lv_label_set_text(label, "Hello NovoLabs!")
    lv_obj_set_style_text_font(label, LV.FONT_XLARGE, LV.PART_MAIN)
    lv_obj_set_style_text_color(label, 0xFFFFFF, LV.PART_MAIN)

    -- Battery & time
    local info = lv_label_create(container)
    local t = rtc_get_time()
    lv_label_set_text(info, string.format(
        "%s  🔋 %d%%", t.iso, battery_percent()))
    lv_obj_set_style_text_color(info, 0x909090, LV.PART_MAIN)
    lv_obj_set_style_text_font(info, LV.FONT_SMALL, LV.PART_MAIN)

    -- IMU readout
    local imu_label = lv_label_create(container)
    local imu = imu_get_accel()
    if imu then
        lv_label_set_text(imu_label, string.format(
            "Accel: x=%.2f y=%.2f z=%.2f", imu.x, imu.y, imu.z))
    end
    lv_obj_set_style_text_color(imu_label, 0x60AAFF, LV.PART_MAIN)

    -- NVS counter (persists across sessions)
    local count = nvs_get_int("open_count", 0) + 1
    nvs_set_int("open_count", count)
    local cnt_label = lv_label_create(container)
    lv_label_set_text(cnt_label, "Opened " .. tostring(count) .. " times")
    lv_obj_set_style_text_color(cnt_label, 0xFFA040, LV.PART_MAIN)

    -- Button with event
    btn = lv_btn_create(container)
    lv_obj_set_width(btn, 200)
    lv_obj_set_style_radius(btn, 10, LV.PART_MAIN)
    lv_obj_set_style_bg_color(btn, 0x2979FF, LV.PART_MAIN)

    local btn_lbl = lv_label_create(btn)
    lv_label_set_text(btn_lbl, LV.SYM_WIFI .. "  Check WiFi")
    lv_obj_center(btn_lbl)

    lv_obj_add_event_cb(btn, function(obj, code)
        local status = wifi_connected() and
            ("Connected to " .. wifi_ssid() .. "  " .. wifi_ip()) or
            "Not connected"
        lv_label_set_text(label, status)
    end, LV.EVENT_CLICKED)

    -- SD image example
    local img = lv_img_create(container)
    lv_img_set_src_sd(img, "/apps/my-app/icon.png")
    lv_obj_set_size(img, 60, 60)

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
