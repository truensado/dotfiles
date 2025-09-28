rule = {
  matches = {
    {
      { "node.name", "equals", "alsa_input.usb-Sony_Interactive_Entertainment_DualSense_Wireless_Controller-00.analog-stereo" },
    },
  },
  apply_properties = {
    ["priority.session"] = 1,
    ["priority.driver"]  = 1,
  },
}

table.insert(alsa_monitor.rules, rule)
