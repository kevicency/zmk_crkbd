/*
 * Answers every Scroll Lock flip from the host (the Signal) with one press and
 * release of the keymap-defined binding, while the configured layer is active.
 */

#define DT_DRV_COMPAT zmk_scroll_lock_keypress

#include <zephyr/kernel.h>
#include <zephyr/devicetree.h>

#include <zmk/behavior.h>
#include <zmk/behavior_queue.h>
#include <zmk/endpoints.h>
#include <zmk/event_manager.h>
#include <zmk/events/hid_indicators_changed.h>
#include <zmk/events/position_state_changed.h>
#include <zmk/keymap.h>

#if DT_HAS_COMPAT_STATUS_OKAY(DT_DRV_COMPAT)

#define SCROLL_LOCK BIT(2) // HID LED usage 0x03 is bit 2 of the LED report
#define TAP_MS 30

static const struct zmk_behavior_binding binding = ZMK_KEYMAP_EXTRACT_BINDING(0, DT_DRV_INST(0));

static struct zmk_endpoint_instance last_endpoint;
static bool last_scroll_lock;

static int scroll_lock_keypress_listener(const zmk_event_t *eh) {
    const struct zmk_hid_indicators_changed *ev = as_zmk_hid_indicators_changed(eh);
    if (ev == NULL) {
        return ZMK_EV_EVENT_BUBBLE;
    }

    const bool scroll_lock = ev->indicators & SCROLL_LOCK;
    const struct zmk_endpoint_instance endpoint = zmk_endpoints_selected();

    // ZMK re-raises this event when the endpoint changes, carrying the new
    // endpoint's LED state. That is a resync, not a Signal. Comparing the
    // endpoint here avoids relying on listener order for zmk_endpoint_changed.
    const bool flipped =
        zmk_endpoint_instance_eq(endpoint, last_endpoint) && scroll_lock != last_scroll_lock;

    last_endpoint = endpoint;
    last_scroll_lock = scroll_lock;

    if (flipped && zmk_keymap_layer_active(DT_INST_PROP(0, layer))) {
        const struct zmk_behavior_binding_event event = {
            .position = INT32_MAX,
            .timestamp = k_uptime_get(),
#if IS_ENABLED(CONFIG_ZMK_SPLIT)
            .source = ZMK_POSITION_STATE_CHANGE_SOURCE_LOCAL,
#endif
        };
        zmk_behavior_queue_add(&event, binding, true, TAP_MS);
        zmk_behavior_queue_add(&event, binding, false, 0);
    }

    return ZMK_EV_EVENT_BUBBLE;
}

ZMK_LISTENER(scroll_lock_keypress, scroll_lock_keypress_listener);
ZMK_SUBSCRIPTION(scroll_lock_keypress, zmk_hid_indicators_changed);

#endif
