# Description:
#   Allows Hubot to know many languages.
#
# Commands:
#   hubot translate me <phrase> - Searches for a translation for the <phrase> and then prints that bad boy out.
#   hubot translate me <source> into <target> <phrase> - Translates <phrase> from <source> into <target>. Both <source> and <target> are optional
#   hubot 翻译 <phrase>
#   hubot 翻译 中文|日语|韩语|英语 到 中文|日语|韩语|英语 <phrase>

languages =
  "af": "Afrikaans",
  "sq": "Albanian",
  "ar": "Arabic",
  "az": "Azerbaijani",
  "eu": "Basque",
  "bn": "Bengali",
  "be": "Belarusian",
  "bg": "Bulgarian",
  "ca": "Catalan",
  "zh-CN": "Simplified Chinese",
  "zh-TW": "Traditional Chinese",
  "hr": "Croatian",
  "cs": "Czech",
  "da": "Danish",
  "nl": "Dutch",
  "en": "English",
  "eo": "Esperanto",
  "et": "Estonian",
  "tl": "Filipino",
  "fi": "Finnish",
  "fr": "French",
  "gl": "Galician",
  "ka": "Georgian",
  "de": "German",
  "el": "Greek",
  "gu": "Gujarati",
  "ht": "Haitian Creole",
  "iw": "Hebrew",
  "hi": "Hindi",
  "hu": "Hungarian",
  "is": "Icelandic",
  "id": "Indonesian",
  "ga": "Irish",
  "it": "Italian",
  "ja": "Japanese",
  "kn": "Kannada",
  "ko": "Korean",
  "la": "Latin",
  "lv": "Latvian",
  "lt": "Lithuanian",
  "mk": "Macedonian",
  "ms": "Malay",
  "mt": "Maltese",
  "no": "Norwegian",
  "fa": "Persian",
  "pl": "Polish",
  "pt": "Portuguese",
  "ro": "Romanian",
  "ru": "Russian",
  "sr": "Serbian",
  "sk": "Slovak",
  "sl": "Slovenian",
  "es": "Spanish",
  "sw": "Swahili",
  "sv": "Swedish",
  "ta": "Tamil",
  "te": "Telugu",
  "th": "Thai",
  "tr": "Turkish",
  "uk": "Ukrainian",
  "ur": "Urdu",
  "vi": "Vietnamese",
  "cy": "Welsh",
  "yi": "Yiddish"

languages_cn = 
  "zh-CN": "中文",
  "ja": "日语",
  "ko ": "韩语",
  "en": "英语"

# getCode = (language,languages) ->
#   for code, lang of languages
#       return code if lang.toLowerCase() is language.toLowerCase()

getCode = (language,languages) ->
  for code, lang of languages
      return code if lang.toLowerCase() is language.toLowerCase()
  for code, lang of languages_cn
      return code if lang is language

	  
module.exports = (robot) ->

  language_choices = (language for _, language of languages).sort().join('|')
  language_cn_choices = (language for _, language of languages_cn).join('|')

  language_choices = language_choices + "|" + language_cn_choices

  pattern = new RegExp('(translate|翻译)(?: me)?' +
                       "(?: (#{language_choices}))?" +
                       "(?: (?:in)?(?:to|到) (#{language_choices}))?" +
                       '(.*)', 'i')
  translateServiceHost = "translate.google.cn"
  robot.respond pattern, (msg) ->
    term   = "\"#{msg.match[4]?.trim()}\""
    origin = if msg.match[2] isnt undefined then getCode(msg.match[2], languages, languages_cn) else 'auto'
    target = if msg.match[3] isnt undefined then getCode(msg.match[3], languages, languages_cn) else 'en'
    console.log "[Translate Debug]: msg.match[1] #{msg.match[1]}\n"
    console.log "[Translate Debug]: msg.match[2] #{msg.match[2]}\n"
    console.log "[Translate Debug]: msg.match[3] #{msg.match[3]}\n"
    console.log "[Translate Debug]: msg.match[4] #{msg.match[4]}\n"
	
    msg.http("https://#{translateServiceHost}/translate_a/single")
      .query({
        client: 't'
        hl: 'en'
        sl: origin
        ssel: 0
        tl: target
        tsel: 0
        q: term
        ie: 'UTF-8'
        oe: 'UTF-8'
        otf: 1
        srcrom: 1
        kc: 1
        tk: 173696.295602
        dt: ['bd', 'ex', 'ld', 'md', 'qca', 'rw', 'rm', 'ss', 't', 'at']
      })
      .header('Accept', '*/*')
      .header('Accept-Language', 'en-US,en;q=0.8,zh-CN;q=0.6,zh;q=0.4')
      .header('Host', 'translate.google.cn')
      .header('Referer', 'http://translate.google.cn/')
      .header('User-Agent', 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.86 Safari/537.36')
      .get() (err, res, body) ->
        if err
          msg.send "Failed to connect to #{translateServiceHost}"
          robot.emit 'error', err, res
          return

        try
          if body.length > 4 and body[0] == '['
            parsed = eval(body)
            language = languages[parsed[2]]
            language_cn = languages_cn[parsed[2]]
            parsed = parsed[0] and parsed[0][0] and parsed[0][0][0]
            parsed and= parsed.trim()
            if parsed
              if msg.match[2] is undefined
                if msg.match[1] is "翻译"
                  msg.send "#{term} 是 #{parsed} 的 #{language_cn} 翻译"  
                else
                  msg.send "#{term} is #{language} for #{parsed}"
              else
                if msg.match[1] is "翻译"
                  msg.send "#{language_cn} #{term} 翻译成 #{languages_cn[target]} 是 #{parsed} "
                else
                  msg.send "The #{language} #{term} translates as #{parsed} in #{languages[target]}"
          else
            throw new SyntaxError 'Invalid JS code'

        catch err
          msg.send "Failed to parse response from #{translateServiceHost}"
          robot.emit 'error', err
