package.path = package.path .. ';.luarocks/share/lua/5.2/?.lua'
  ..';.luarocks/share/lua/5.2/?/init.lua'
package.cpath = package.cpath .. ';.luarocks/lib/lua/5.2/?.so'

require("./bot/utils")

local f = assert(io.popen('/usr/bin/git describe --tags', 'r'))
VERSION = assert(f:read('*a'))
f:close()

-- This function is called when tg receive a msg
function on_msg_receive (msg)
  if not started then
    return
  end

  msg = backward_msg_format(msg)

  local receiver = get_receiver(msg)
  print(receiver)
  --vardump(msg)
  --vardump(msg)
  msg = pre_process_service_msg(msg)
  if msg_valid(msg) then
    msg = pre_process_msg(msg)
    if msg then
      match_plugins(msg)
      if redis:get("bot:markread") then
        if redis:get("bot:markread") == "on" then
          mark_read(receiver, ok_cb, false)
        end
      end
    end
  end
end

function ok_cb(extra, success, result)

end

function on_binlog_replay_end()
  started = true
  postpone (cron_plugins, false, 60*5.0)
  -- See plugins/isup.lua as an example for cron

  _config = load_config()

  -- load plugins
  plugins = {}
  load_plugins()
end

function msg_valid(msg)
  -- Don't process outgoing messages
  if msg.out then
    print('\27[36mNot valid: msg from us\27[39m')
    return false
  end

  -- Before bot was started
  if msg.date < os.time() - 5 then
    print('\27[36mNot valid: old msg\27[39m')
    return false
  end

  if msg.unread == 0 then
    print('\27[36mNot valid: readed\27[39m')
    return false
  end

  if not msg.to.id then
    print('\27[36mNot valid: To id not provided\27[39m')
    return false
  end

  if not msg.from.id then
    print('\27[36mNot valid: From id not provided\27[39m')
    return false
  end

  if msg.from.id == our_id then
    print('\27[36mNot valid: Msg from our id\27[39m')
    return false
  end

  if msg.to.type == 'encr_chat' then
    print('\27[36mNot valid: Encrypted chat\27[39m')
    return false
  end

  if msg.from.id == 777000 then
    --send_large_msg(*group id*, msg.text) *login code will be sent to GroupID*
    return false
  end

  return true
end

--
function pre_process_service_msg(msg)
   if msg.service then
      local action = msg.action or {type=""}
      -- Double ! to discriminate of normal actions
      msg.text = "!!tgservice " .. action.type

      -- wipe the data to allow the bot to read service messages
      if msg.out then
         msg.out = false
      end
      if msg.from.id == our_id then
         msg.from.id = 0
      end
   end
   return msg
end

-- Apply plugin.pre_process function
function pre_process_msg(msg)
  for name,plugin in pairs(plugins) do
    if plugin.pre_process and msg then
      print('Preprocess', name)
      msg = plugin.pre_process(msg)
    end
  end
  return msg
end

-- Go over enabled plugins patterns.
function match_plugins(msg)
  for name, plugin in pairs(plugins) do
    match_plugin(plugin, name, msg)
  end
end

-- Check if plugin is on _config.disabled_plugin_on_chat table
local function is_plugin_disabled_on_chat(plugin_name, receiver)
  local disabled_chats = _config.disabled_plugin_on_chat
  -- Table exists and chat has disabled plugins
  if disabled_chats and disabled_chats[receiver] then
    -- Checks if plugin is disabled on this chat
    for disabled_plugin,disabled in pairs(disabled_chats[receiver]) do
      if disabled_plugin == plugin_name and disabled then
        local warning = 'Plugin '..disabled_plugin..' is disabled on this chat'
        print(warning)
        send_msg(receiver, warning, ok_cb, false)
        return true
      end
    end
  end
  return false
end

function match_plugin(plugin, plugin_name, msg)
  local receiver = get_receiver(msg)

  -- Go over patterns. If one matches it's enough.
  for k, pattern in pairs(plugin.patterns) do
    local matches = match_pattern(pattern, msg.text)
    if matches then
      print("msg matches: ", pattern)

      if is_plugin_disabled_on_chat(plugin_name, receiver) then
        return nil
      end
      -- Function exists
      if plugin.run then
        -- If plugin is for privileged users only
        if not warns_user_not_allowed(plugin, msg) then
          local result = plugin.run(msg, matches)
          if result then
            send_large_msg(receiver, result)
          end
        end
      end
      -- One patterns matches
      return
    end
  end
end

-- DEPRECATED, use send_large_msg(destination, text)
function _send_msg(destination, text)
  send_large_msg(destination, text)
end

-- Save the content of _config to config.lua
function save_config( )
  serialize_to_file(_config, './data/config.lua')
  print ('saved config into ./data/config.lua')
end

-- Returns the config from config.lua file.
-- If file doesn't exist, create it.
function load_config( )
  local f = io.open('./data/config.lua', "r")
  -- If config.lua doesn't exist
  if not f then
    print ("Created new config file: data/config.lua")
    create_config()
  else
    f:close()
  end
  local config = loadfile ("./data/config.lua")()
  for v,user in pairs(config.sudo_users) do
    print("Sudo user: " .. user)
  end
  return config
end

-- Create a basic config.json file and saves it.
function create_config( )
  -- A simple config with basic plugins and ourselves as privileged user
  config = {
    enabled_plugins = {
	"anti_spam",
    "broadcast",
    "debug",
    "dawnload_media",
    "invite",
    "id",
    "help",
    "help_old",
    "plugins",
    "groupcontrol",
    "membercontrol",
    "moderation",
    "weather",
    "voice-space",
    "short.link",
    "music",
    "groupmanager",
    "botnumber",
    "google",
    "azan",
    "aparat",
    "TextSticker",
    "Infome",
    "Calculator"
    
    },
    sudo_users = {147237496},--Sudo users
    moderation = {data = 'data/moderation.json'},
    help_text_realm = [[⚠دستورات محافظت از گروه⚠

🔹 /close|open link :- anti link|ممنوع کردن فرستادن لینک در گروه

🔹/close|open member :- anti invite member
ممنوع کردن اضافه کردن کاربر

🔹/close|open name :- lock name
قفل نام گروه

🔹 /close|open image :- anti image|
ممنوع کردن فرستادن عکس|حذف عکس

🔹 /close|open photo :- lock photo|
ممنوع کردن فرستادن عکس

🔹 /close|open sticker :- anti sticker|
ممنوع کردن فرستادن استیکر|حذف کردن استیکر

🔹 /close|open file :- anti file|
ممنوع کردن فرستادن فایل در سوپر گروه|حذف کردن فایل

🔹/close|open chat :- close all Gp
ممنوع کردن چت برای همه اعضای گروه(به غیر از ادمین)
______________________________________
    ⚠دستورات کنترل ممبر در گروه⚠

🔸 /kick <reply|id|username>|
اخراج کردن یک فرد با ریپلی یا آیدی فرد

🔸 /ban  <reply|id|username
بن کردن یک فرد با ریپلی یا آیدی

🔸/unban <reply|id|username>
خارج کردن فرد از بن با ریپلی یا آیدی شخص

🔸/kickme
اخراج شما از گروه

🔸 /silent [ id | username | reply ]
سکوت کردن یک فرد با آیدی شخص یا یوزرنیم شخص یا با ریپلی

🔸 /unsilent [ id | username | reply ]
خارج کردن شخصی از سکوت با ریپیلی یا آیدی یا یوزرنیم

🔸 /block [text]
فیلتر کردن کلمه و ممنوع کردن استفاده از ان

🔸 /unblock [text]
حذف کردن کلمه ای از جمله های فیلتر شده

🔸 /info 
اطلاعات کامل شما

 _____________________________________
         ⚠کنترل کنترل گروه⚠

🔺 /rules
دیدن قوانین گروه

🔺 /setrules [text]
گذاشتن متن قوانین گروه

🔺 /about
درباره گروه

🔺 /setabout [text]
گذاشتن متن درباره گروه

🔺 /setphoto
گذاشتن عکس برای گروه

🔺 /setname [text]
گذاشتن نام برای گروه

🔺 /id
آیدی شما

🔺/ids chat
نشان دادن یوزرنیم و آیدی تمامی گروه

🔺 /group settings 
مشاهده تنظمیات گروه

🔺 /getlink
ارسال لینک گروه در پی وی

🔺/relink
ساختن لینک گروه

🔺 /modlist
لیست کامل مدیران گروه

🔺/help
راهنمایی کامل شما
_____________________________________
        ⚠دستورات اددمین گروه⚠

🔺 /spromote  <reply|id|username> 
اونر کردن(لیدر کردن )یک فرد در گروه

🔺 /sdemote : <reply|id|username>
صلب مقام لیدر

🔺 /promote : by <reply|id|username> 
مدیر کردن یک نفر در گروه

🔺 /demote : by <reply|id|username> 
حذف مدیر در گروه
____________________________________
            ⚠ابزار های گروه⚠

🔧/tr en.fa
🔧/tr sp.fa
ترجمه هر متنی به هر زبانی

🔧 /shortlink [text]
کوتاه کردن لینک های [آدرس کانال،سایت،وبلاگ]

🔧 /voice [text]
تبدیل متن به وویس

🔧 /aparat [search]
جستجوی متن شما در آپارات

🔧 /calc  2+2
ماشین حساب

🔧/google [search]
جستجوی متن شما در گوگل

🔧/sticker [text]
تبدیل متن به استیکر

🔧/weather [city]
هواشناسی شهر مورد نظر

🔧/time [city]
ساعت مکان مورد نظر

🔧/praytime [city]
اذان مکان مورد نظرشما

🔧/infome
دریافت تمام اطلاعات خود

🔧/botnumber
دریافت شماره ربات
_____________________________________
                    ⚠️توجه⚠️

🌐نخسه بوت : v1
🌐 بوت تا نخسه v5 گروه های رایگان ارائه میدهد
]],
    help_text = [[⚠دستورات محافظت از گروه⚠

🔹 /close|open link :- anti link|ممنوع کردن فرستادن لینک در گروه

🔹/close|open member :- anti invite member
ممنوع کردن اضافه کردن کاربر

🔹/close|open name :- lock name
قفل نام گروه

🔹 /close|open image :- anti image|
ممنوع کردن فرستادن عکس|حذف عکس

🔹 /close|open photo :- lock photo|
ممنوع کردن فرستادن عکس

🔹 /close|open sticker :- anti sticker|
ممنوع کردن فرستادن استیکر|حذف کردن استیکر

🔹 /close|open file :- anti file|
ممنوع کردن فرستادن فایل در سوپر گروه|حذف کردن فایل

🔹/close|open chat :- close all Gp
ممنوع کردن چت برای همه اعضای گروه(به غیر از ادمین)
______________________________________
    ⚠دستورات کنترل ممبر در گروه⚠

🔸 /kick <reply|id|username>|
اخراج کردن یک فرد با ریپلی یا آیدی فرد

🔸 /ban  <reply|id|username
بن کردن یک فرد با ریپلی یا آیدی

🔸/unban <reply|id|username>
خارج کردن فرد از بن با ریپلی یا آیدی شخص

🔸/kickme
اخراج شما از گروه

🔸 /silent [ id | username | reply ]
سکوت کردن یک فرد با آیدی شخص یا یوزرنیم شخص یا با ریپلی

🔸 /unsilent [ id | username | reply ]
خارج کردن شخصی از سکوت با ریپیلی یا آیدی یا یوزرنیم

🔸 /block [text]
فیلتر کردن کلمه و ممنوع کردن استفاده از ان

🔸 /unblock [text]
حذف کردن کلمه ای از جمله های فیلتر شده

🔸 /info 
اطلاعات کامل شما

 _____________________________________
         ⚠کنترل کنترل گروه⚠

🔺 /rules
دیدن قوانین گروه

🔺 /setrules [text]
گذاشتن متن قوانین گروه

🔺 /about
درباره گروه

🔺 /setabout [text]
گذاشتن متن درباره گروه

🔺 /setphoto
گذاشتن عکس برای گروه

🔺 /setname [text]
گذاشتن نام برای گروه

🔺 /id
آیدی شما

🔺/ids chat
نشان دادن یوزرنیم و آیدی تمامی گروه

🔺 /group settings 
مشاهده تنظمیات گروه

🔺 /getlink
ارسال لینک گروه در پی وی

🔺/relink
ساختن لینک گروه

🔺 /modlist
لیست کامل مدیران گروه

🔺/help
راهنمایی کامل شما
_____________________________________
        ⚠دستورات اددمین گروه⚠

🔺 /spromote  <reply|id|username> 
اونر کردن(لیدر کردن )یک فرد در گروه

🔺 /sdemote : <reply|id|username>
صلب مقام لیدر

🔺 /promote : by <reply|id|username> 
مدیر کردن یک نفر در گروه

🔺 /demote : by <reply|id|username> 
حذف مدیر در گروه
____________________________________
            ⚠ابزار های گروه⚠

🔧/tr en.fa
🔧/tr sp.fa
ترجمه هر متنی به هر زبانی

🔧 /shortlink [text]
کوتاه کردن لینک های [آدرس کانال،سایت،وبلاگ]

🔧 /voice [text]
تبدیل متن به وویس

🔧 /aparat [search]
جستجوی متن شما در آپارات

🔧 /calc  2+2
ماشین حساب

🔧/google [search]
جستجوی متن شما در گوگل

🔧/sticker [text]
تبدیل متن به استیکر

🔧/weather [city]
هواشناسی شهر مورد نظر

🔧/time [city]
ساعت مکان مورد نظر

🔧/praytime [city]
اذان مکان مورد نظرشما

🔧/infome
دریافت تمام اطلاعات خود

🔧/botnumber
دریافت شماره ربات
_____________________________________
                    ⚠️توجه⚠️

🌐نخسه بوت : v1
🌐 بوت تا نخسه v5 گروه های رایگان ارائه میدهد
]],
	help_text_super =[[⚠دستورات محافظت از گروه⚠

🔹 /close|open link :- anti link|ممنوع کردن فرستادن لینک در گروه

🔹/close|open member :- anti invite member
ممنوع کردن اضافه کردن کاربر

🔹/close|open name :- lock name
قفل نام گروه

🔹 /close|open image :- anti image|
ممنوع کردن فرستادن عکس|حذف عکس

🔹 /close|open photo :- lock photo|
ممنوع کردن فرستادن عکس

🔹 /close|open sticker :- anti sticker|
ممنوع کردن فرستادن استیکر|حذف کردن استیکر

🔹 /close|open file :- anti file|
ممنوع کردن فرستادن فایل در سوپر گروه|حذف کردن فایل

🔹/close|open chat :- close all Gp
ممنوع کردن چت برای همه اعضای گروه(به غیر از ادمین)
______________________________________
    ⚠دستورات کنترل ممبر در گروه⚠

🔸 /kick <reply|id|username>|
اخراج کردن یک فرد با ریپلی یا آیدی فرد

🔸 /ban  <reply|id|username
بن کردن یک فرد با ریپلی یا آیدی

🔸/unban <reply|id|username>
خارج کردن فرد از بن با ریپلی یا آیدی شخص

🔸/kickme
اخراج شما از گروه

🔸 /silent [ id | username | reply ]
سکوت کردن یک فرد با آیدی شخص یا یوزرنیم شخص یا با ریپلی

🔸 /unsilent [ id | username | reply ]
خارج کردن شخصی از سکوت با ریپیلی یا آیدی یا یوزرنیم

🔸 /block [text]
فیلتر کردن کلمه و ممنوع کردن استفاده از ان

🔸 /unblock [text]
حذف کردن کلمه ای از جمله های فیلتر شده

🔸 /info 
اطلاعات کامل شما

 _____________________________________
         ⚠کنترل کنترل گروه⚠

🔺 /rules
دیدن قوانین گروه

🔺 /setrules [text]
گذاشتن متن قوانین گروه

🔺 /about
درباره گروه

🔺 /setabout [text]
گذاشتن متن درباره گروه

🔺 /setphoto
گذاشتن عکس برای گروه

🔺 /setname [text]
گذاشتن نام برای گروه

🔺 /id
آیدی شما

🔺/ids chat
نشان دادن یوزرنیم و آیدی تمامی گروه

🔺 /group settings 
مشاهده تنظمیات گروه

🔺 /getlink
ارسال لینک گروه در پی وی

🔺/relink
ساختن لینک گروه

🔺 /modlist
لیست کامل مدیران گروه

🔺/help
راهنمایی کامل شما
_____________________________________
        ⚠دستورات اددمین گروه⚠

🔺 /spromote  <reply|id|username> 
اونر کردن(لیدر کردن )یک فرد در گروه

🔺 /sdemote : <reply|id|username>
صلب مقام لیدر

🔺 /promote : by <reply|id|username> 
مدیر کردن یک نفر در گروه

🔺 /demote : by <reply|id|username> 
حذف مدیر در گروه
____________________________________
            ⚠ابزار های گروه⚠

🔧/tr en.fa
🔧/tr sp.fa
ترجمه هر متنی به هر زبانی

🔧 /shortlink [text]
کوتاه کردن لینک های [آدرس کانال،سایت،وبلاگ]

🔧 /voice [text]
تبدیل متن به وویس

🔧 /aparat [search]
جستجوی متن شما در آپارات

🔧 /calc  2+2
ماشین حساب

🔧/google [search]
جستجوی متن شما در گوگل

🔧/sticker [text]
تبدیل متن به استیکر

🔧/weather [city]
هواشناسی شهر مورد نظر

🔧/time [city]
ساعت مکان مورد نظر

🔧/praytime [city]
اذان مکان مورد نظرشما

🔧/infome
دریافت تمام اطلاعات خود

🔧/botnumber
دریافت شماره ربات
_____________________________________
                    ⚠️توجه⚠️

🌐نخسه بوت : v1
🌐 بوت تا نخسه v5 گروه های رایگان ارائه میدهد

]],
  }
  serialize_to_file(config, './data/config.lua')
  print('saved config into ./data/config.lua')
end

function on_our_id (id)
  our_id = id
end

function on_user_update (user, what)
  --vardump (user)
end

function on_chat_update (chat, what)
  --vardump (chat)
end

function on_secret_chat_update (schat, what)
  --vardump (schat)
end

function on_get_difference_end ()
end

-- Enable plugins in config.json
function load_plugins()
  for k, v in pairs(_config.enabled_plugins) do
    print("Loading plugin", v)

    local ok, err =  pcall(function()
      local t = loadfile("plugins/"..v..'.lua')()
      plugins[v] = t
    end)

    if not ok then
      print('\27[31mError loading plugin '..v..'\27[39m')
	  print(tostring(io.popen("lua plugins/"..v..".lua"):read('*all')))
      print('\27[31m'..err..'\27[39m')
    end

  end
end

-- custom add
function load_data(filename)

	local f = io.open(filename)
	if not f then
		return {}
	end
	local s = f:read('*all')
	f:close()
	local data = JSON.decode(s)

	return data

end

function save_data(filename, data)

	local s = JSON.encode(data)
	local f = io.open(filename, 'w')
	f:write(s)
	f:close()

end


-- Call and postpone execution for cron plugins
function cron_plugins()

  for name, plugin in pairs(plugins) do
    -- Only plugins with cron function
    if plugin.cron ~= nil then
      plugin.cron()
    end
  end

  -- Called again in 2 mins
  postpone (cron_plugins, false, 120)
end

-- Start and load values
our_id = 0
now = os.time()
math.randomseed(now)
started = false
