using Telegram, Telegram.API, JLD2

f = open("Save/telegram.txt")
text_vector = readlines(f)
token = text_vector[1]
chat_id = text_vector[2]
Base.close(f)

TelegramClient(token, chat_id=chat_id)
function printm(m::String)
    sendMessage(text=m)
end

@load "Save/seed.jld2" data_state learn_state imp_state
