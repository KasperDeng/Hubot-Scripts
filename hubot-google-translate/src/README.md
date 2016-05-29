# hubot-google-translate

Allows Hubot to know many languages using Google Translate

See [`src/google-translate.coffee`](src/google-translate.coffee) for full documentation.

## Installation

In hubot project repo, run:

`npm install hubot-google-translate --save`

Then add **hubot-google-translate** to your `external-scripts.json`:

```json
[
  "hubot-google-translate"
]
```

## Sample Interaction

```
user> hubot translate me bienvenu
hubot> " bienvenu" is Turkish for " Bienvenu "
user> "剑桥大学" is Simplified Chinese for " Cambridge "
hubot> "剑桥大学" 是 " Cambridge " 的 中文 翻译
user> hubot translate me Simplified Chinese to english 剑桥大学
hubot> The Simplified Chinese "剑桥大学" translates as " Cambridge " in English
user> 翻译 剑桥大学
hubot> "剑桥大学" 是 " Cambridge " 的 中文 翻译
user> 翻译 中文 到 英语 剑桥大学
hubot> 中文 "剑桥大学" 翻译成 英语 是 " Cambridge "
```
