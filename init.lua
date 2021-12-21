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
        if not language_available(sender_language) then
            sender_language = "en"
        end
        for _,player in pairs(minetest.get_connected_players()) do
            local receiver_name = player:get_player_name()
            if receiver_name ~= name then
                local receiver_language = minetest.get_player_information(receiver_name).lang_code
                if not language_available(receiver_language) then
                    receiver_language = "en"
                end
                local url = 'http://localhost:5000/translate'
                local post_data = { q = message, source = sender_language, target = receiver_language }
                local headers = { ["Accept"] = "accept: application/json", ["Content-Type"] = "application/x-www-form-urlencoded" }
                local request = { url = url, post_data = post_data, extra_headers = headers }
                http.fetch(request, function(response)
                    if not response.completed then
                        return
                    end
                    local data_json = minetest.parse_json(response.data)
                    if data_json then
                        minetest.chat_send_player(receiver_name, "<" .. name .. "> " .. data_json.translatedText)
                    else
                        local error_message = "Failed to translate message from "
                            .. name .. " (" .. sender_language .. ") " .. " to " .. 
                            receiver_name .. " (" .. receiver_language .. ") "
                        handle_failure(error_message)
                        minetest.chat_send_player(receiver_name, "<" .. name .. "> " .. message)
                    end
                end)
            end
        end
        return true
    end
end)

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
    minetest.log("error", "Chat translator error!")
    minetest.log("error", message)
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