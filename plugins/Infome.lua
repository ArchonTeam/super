do
function run(msg, matches)
  return "🔺 #نام گروه : "..msg.to.title.."\n🔻 #شناسه گروه : "..msg.from.id.."\n🔹 #نام شما : "..(C or '---').."\n🔸 #نام اول : "..(msg.from.first_name or '---').."\n🔹 #نام آخر : "..(msg.from.last_name or '---').."\n🔸 #آیدی : "..msg.from.id.."\n🆔 #یوزرنیم : @"..(msg.from.username or '---').."\n📱 #شماره تلفن : +"..(msg.from.phone or '').."\nℹ️#رابط کاربری:---".."\n🆔 #یوزرنیم : telegram.me/"..(msg.from.username or '---').."\n"
end
return {
  description = "infome", 
  usage = "infomg",
  patterns = {
    "^/[Ii]nfome$",
  },
  run = run
}
end