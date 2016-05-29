# Description:
#   Allows Hubot to get beauty's image.
#
# Commands:
#   hubot 美图

fs = require 'fs'
# wget = require '../node_modules/wget'
# yaml = require '../node_modules/hubot-ece/node_modules/js-yaml/lib/js-yaml.js'
# configContent = fs.readFileSync './node_modules/hubot-ece/config.yaml' , 'utf8'
# config = yaml.load configContent

module.exports = (robot) ->
  # robot.respond /(?:)/i, (msg) ->
  #   _getBeautyImage msg

  robot.respond /(?:美图)/i, (msg) ->
    _getCalvinImage msg

_getCalvinImage = (msg) ->
  imgDir = "/home/kasper/BeautyImageDir/"
  if fs.existsSync imgDir
    fileList = fs.readdirSync imgDir
    index = Math.floor(Math.random() * fileList.length)
    msg.emote imgDir + fileList[index]
