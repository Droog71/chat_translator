--[[
    Minetest Chat Translator
    Version: 1
    License: AGPLv3
    
    LibreTranslate
    Free and Open Source Machine Translation API
    License: AGPLv3 
]]--

local languages = {}
local http = minetest.request_http_api()

--returns an error if the mod is not trusted
 minetest.register_on_prejoinplayer(function(pname)
    if not http then
        return "\n\nChat Translator needs to be added to your trusted mods list.\n" ..
            "To do so, click on the 'Settings' tab in the main menu.\n" ..
            "Click the 'All Settings' button and in the search bar, enter 'trusted'.\n" ..
            "Click the 'Edit' button and add 'chat_translator' to the list."
    end
    http.fetch({ url = "http://localhost:5000/languages" }, get_languages)
end)

--intercepts chat messages and sends an http request to libretranslate
minetest.register_on_chat_message(function(name, message)
    if http then
        local sender_language = minetest.get_player_information(name).lang_code
        if sender_language == "" then
            sender_language = "en" 
        end
        if not language_available(sender_language) then
            return false
        else
            send_to_all(message, name, sender_language, false)
        end
        return true
    end
end)

--overrides the builtin direct message function
minetest.override_chatcommand("msg", {
    params = "",
    description = "",
    privs = { shout = true },
    func = function(name, param)
        local receiver_name, message = param:match("^(%S+)%s(.+)$")
        if not receiver_name then
            send_server_msg("Invalid usage. Try " .. "[/msg name message]", name)
            return true
        end
        if not minetest.get_player_by_name(receiver_name) then
            send_server_msg("The recipient is not online.", name)
            return true
        end
        send_dm(message, name, receiver_name)
        send_server_msg("Message sent.", name)
        return true
    end,
})

--overrides the builtin emote function
minetest.override_chatcommand("me", {
    params = "",
    description = "",
    privs = { shout = true },
    func = function(name, param)
        if param ~= "" then
            local sender_language = minetest.get_player_information(name).lang_code
            if sender_language == "" then
                sender_language = "en" 
            end
            if not language_available(sender_language) then
                minetest.chat_send_all("* " .. name .. " " .. message)
            else
                send_to_all(param, name, sender_language, true)
            end
            return true
        else
            send_server_msg("Invalid usage. Try [/me does something]", name)
            return true
        end
    end,
})
 
 --sends a translated message from the server to a player
function send_server_msg(message, receiver_name)
    local receiver_language = minetest.get_player_information(receiver_name).lang_code
    local params = {
        message = message,
        sender_name = "Minetest",
        receiver_name = receiver_name,
        sender_language = "en",
        receiver_language = receiver_language,
        prefix = "<",
        suffix = "> "
    }
    if language_available(receiver_language) == false or receiver_language == "en" then
        minetest.chat_send_player(
            params.receiver_name,
            params.prefix ..
            params.sender_name ..
            params.suffix ..
            message
        )
    else
        send_message(params)
    end
end
 
--translates and sends a direct message
function send_dm(message, sender_name, receiver_name)
    local sender_language = minetest.get_player_information(sender_name).lang_code
    local receiver_language = minetest.get_player_information(receiver_name).lang_code
    if sender_language == "" then sender_language = "en" end
    if receiver_language == "" or language_available(receiver_language) == false then 
        receiver_language = "en"
    end
    local params = {
        message = message,
        sender_name = sender_name,
        receiver_name = receiver_name,
        sender_language = sender_language,
        receiver_language = receiver_language,
        prefix = "<",
        suffix = "> ► <" .. receiver_name .. "> "
    }
    if language_available(sender_language) == false or sender_language == receiver_language then
        minetest.chat_send_player(
            params.receiver_name,
            params.prefix ..
            params.sender_name ..
            params.suffix ..
            message
        )
    else
        send_message(params)
    end
end

--translates and delivers the message to all players
function send_to_all(message, sender_name, sender_language, emote)
    local prefix = emote and "* " or "<" 
    local suffix = emote and " " or "> "
    for _,player in pairs(minetest.get_connected_players()) do
        local receiver_name = player:get_player_name()
        local receiver_language = minetest.get_player_information(receiver_name).lang_code
        if sender_language == receiver_language then
            minetest.chat_send_player(receiver_name, prefix .. sender_name .. suffix .. message)
        else
            if receiver_language == "" or language_available(receiver_language) == false then 
                receiver_language = "en"
            end
            local params = {
                message = message,
                sender_name = sender_name,
                receiver_name = receiver_name,
                sender_language = sender_language,
                receiver_language = receiver_language,
                prefix = prefix,
                suffix = suffix
            }
            send_message(params)
        end
    end
end

--translates the message and sends it to the receiver
function send_message(params)
    local url = 'http://localhost:5000/translate'
    local post_data = { 
        q = params.message,
        source = params.sender_language,
        target = params.receiver_language 
    }
    local headers = {
        ["Accept"] = "accept: application/json", 
        ["Content-Type"] = "application/x-www-form-urlencoded" 
    }
    local request = { url = url, post_data = post_data, extra_headers = headers }
    http.fetch(request, function(response)
        if not response.completed then
            return
        end
        local msg = params.message
        local data_json = minetest.parse_json(response.data)
        if data_json then
            msg = data_json.translatedText
        else
            handle_failure("Failed to translate a message.")
        end
        minetest.chat_send_player(
            params.receiver_name,
            params.prefix ..
            params.sender_name ..
            params.suffix ..
            msg
        )
    end)
end

--gets all language codes from libretranslate
function get_languages(response)
    if not response.completed then
        return
    end
    local data_json = minetest.parse_json(response.data)
    if data_json then
        languages = {}
        for _,language in pairs(data_json) do
            table.insert(languages, language.code)
        end
    else
        handle_failure("Failed to retrieve list of languages from libretranslate.")
    end
end

--handles failed http requests
function handle_failure(message)
    minetest.log("error", "Chat Translator: " .. message)
    minetest.log("error", "Please ensure libretranslate is available at http://localhost:5000/translate")
end

--checks if libretranslate supports the language
function language_available(language)
    if languages == {} then
        http.fetch({ url = "http://localhost:5000/languages" }, get_languages)
    end
    if contains_value(languages,language) then
        return true
    end
    return false
end

--returns true if the table contains the given value
function contains_value(table, value)
    for k, v in pairs(table) do
        if v == value then return true end
    end
end