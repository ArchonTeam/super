do

function run(msg, matches)
send_contact(get_receiver(msg), "+639380036920", "Soft", "TG", ok_cb, false)
end

return {
patterns = {
"^!botnumber$"

},
run = run
}

end
