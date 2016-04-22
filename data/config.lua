do local _ = {
  disabled_channels = {},
  enabled_plugins = {
    "id",
    "plugins",
    "moderation",
    "groupcontrol",
    "membercontrol",
    "help",
    "invite",
    "anti_spam",
    "auto_leave"
  },
  moderation = {
    data = "data/moderation.json"
  },
  sudo_users = {
    147237496
  }
}
return _
end