# Zephyr module sources (see zephyr/module.yml). Central half only: the left
# half enables CONFIG_ZMK_HID_INDICATORS in config/corne_left.conf.
if(CONFIG_ZMK_HID_INDICATORS AND ((NOT CONFIG_ZMK_SPLIT) OR CONFIG_ZMK_SPLIT_ROLE_CENTRAL))
  target_sources(app PRIVATE src/scroll_lock_keypress.c)
endif()
