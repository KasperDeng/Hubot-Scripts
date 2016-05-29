# Description:
#   Allows Hubot to get the history of today. 
#
# Commands:
#   hubot 历史上的今天

module.exports = (robot) ->
  robot.respond /(?:历史上的今天)/i, (msg) ->
    tellTodayHistory msg

tellTodayHistory = (msg) ->
  appKey = "" # Your appKey
  today = new Date()
  month = today.getMonth() + 1
  date = today.getDate()
  params = "yue=#{month}&ri=#{date}&type=1&page=1&rows=20&dtype=JOSN&format=false"
  urlPath = "http://apis.baidu.com/avatardata/historytoday/lookup?#{params}"
  req = msg.http(urlPath)
  req.header "apikey", "" # Your apiKey
  req.get() (err, res, body) ->
    switch res.statusCode
      when 200
        #console.log "body #{body}"
        jsonBody = JSON.parse body
        num = jsonBody.total
        if num > 0
          replyContent = ""
          while num -= 1
            item = jsonBody.result[num]
            content = "#{item.year}.#{item.month}.#{item.day}: #{item.title}\n"
            replyContent += content
          msg.send replyContent
      when 404
        msg.send "数据已消失: #{res.statusCode}"
      else
        msg.send "Debug: #{res.statusCode}"
