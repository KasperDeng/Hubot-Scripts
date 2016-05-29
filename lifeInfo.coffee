# Description:
#   Allows Hubot to get PM2.5 index, oil price.
#
# Commands:
#   hubot pm2.5 城市
#   hubot 油价 省份

module.exports = (robot) ->
  robot.respond /(?:pm2.5) (.*)/i, (msg) ->
    getPM25Index msg

  robot.respond /(?:油价|gasoline) (.*)/i, (msg) ->
    getOidPrice msg

getPM25Index = (msg) ->
  city = new Buffer msg.match[1]
  params = "city=#{city}"
  urlPath = "http://apis.baidu.com/apistore/aqiservice/aqi?#{params}"
  req = msg.http(urlPath)
  req.header "apikey", "" # Your apiKey
  req.get() (err, res, body) ->
    switch res.statusCode
      when 200
        jsonBody = JSON.parse body
        data = jsonBody.retData
        content = "数据采集时间: #{data.time}\n空气质量指数: #{data.aqi}\n空气等级: #{data.level}\n"
        if data.core
          content + "首要污染物: #{data.core}"
        msg.send content
      when 404
        msg.send "数据已消失: #{res.statusCode}"
      else
        msg.send "Debug: #{res.statusCode}"

getOidPrice = (msg) ->
  province = new Buffer msg.match[1]
  appKey = "" # Your appKey
  params = "province=#{province}&appkey=#{appKey}"
  urlPath = "http://apis.baidu.com/netpopo/oil/oil?#{params}"
  req = msg.http(urlPath)
  req.header "apikey", "" #Your apiKey
  req.get() (err, res, body) ->
    switch res.statusCode
      when 200
        console.log body
        jsonBody = JSON.parse body
        result = jsonBody.result
        msg.send "#90:#{result.oil90}\n#93:#{result.oil93}\n#97:#{result.oil97}\n#0 :#{result.oil0}"
      when 404
        msg.send "数据已消失: #{res.statusCode}"
      else
        msg.send "Debug: #{res.statusCode}"
