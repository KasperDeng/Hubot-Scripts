# Description:
#   Allows Hubot to get stock info.
#
# Commands:
#   hubot 股票|stock stockID

module.exports = (robot) ->
  robot.respond /(?:stock|股票) (.*)/i, (msg) ->
    getStockInfo msg

getStockInfo = (msg) ->
  stockId = msg.match[1]
  hasStockId = true
  if stockId
    if stockId.startsWith "6"
      stockId = "sh" + stockId
    else if stockId.startsWith "0" or stockId.startsWith "3"
      stockId = "sz" + stockId
  else
    hasStockId = false
    stockId = "sz000001"
  list = 2 ## default only query one stock
  params = "stockid=#{stockId}&list=#{list}"
  urlPath = "http://apis.baidu.com/apistore/stockservice/stock?#{params}"
  req = msg.http(urlPath)
  req.header "apikey", "" # Your apiKey
  req.get() (err, res, body) ->
    switch res.statusCode
      when 200
        jsonBody = JSON.parse body
        if jsonBody.errNum is 0
          content = "====================\n"
          if hasStockId
            stockinfo = jsonBody.retData.stockinfo[0]
            if stockinfo.name isnt "FAILED"
              content = "#{stockinfo.name}(#{stockinfo.code})\n#{stockinfo.date} #{stockinfo.time}\n"
              content += "当前价格: #{stockinfo.currentPrice}\n"
              content += "今日开盘价: #{stockinfo.OpenningPrice}\n昨日收盘价: #{stockinfo.closingPrice}\n"
              content += "今日最高价: #{stockinfo.hPrice}\n今日最低价: #{stockinfo.lPrice}\n"
              content += "成交的股票数: #{stockinfo.totalNumber}\n成交额: #{stockinfo.turnover} 元\n\n"

          for _, marketInfo of jsonBody.retData.market
            content += "#{marketInfo.name} #{marketInfo.curdot} #{marketInfo.rate}%\n"
            if marketInfo.dealnumber
              content += "交易量: #{marketInfo.dealnumber}手\n"
            if marketInfo.turnover
              content += "成交额: #{marketInfo.turnover} 万元\n"
            content += "====================\n"
        msg.send content
      when 404
        msg.send "数据已消失: #{res.statusCode}"
      else
        msg.send "Debug: #{res.statusCode}"
