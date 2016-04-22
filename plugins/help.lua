local function run(msg, matches)
  if is_chat_msg(msg) then
    local text = [[‌⚠دستورات محافظت از گروه⚠

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

🔺 /spromote  <reply|id|username> 
اونر کردن(لیدر کردن )یک فرد در گروه

🔺 /sdemote : <reply|id|username>
صلب مقام لیدر

🔺 /promote : by <reply|id|username> 
مدیر کردن یک نفر در گروه

🔺 /demote : by <reply|id|username> 
حذف مدیر در گروه

                   🚀 @soft_TG 🚀

🤖 Bot version : 1.0.0
🤖 Bot Antispam Group
      
                      🔘TG TEAM🔘
]]
    return text
  else
    local text = [[aaa]]
    --return text
  end
end

return {
  description = "Help plugin. Get info from other plugins.  ", 
  usage = {
    "!help: Show list of plugins.",
  },
  patterns = {
    "^/(help)$",
  }, 
  run = run,
}
