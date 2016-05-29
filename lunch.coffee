# Description:
#   Allows Hubot to interact with Dianping.com to recommand the restaurant.
#
# Commands:
#   hubot i am hungry - recommand a nearby restaurant via dianping.com API
#   hubot *饿* - 由大众点评推荐附近餐馆
#

module.exports = (robot) ->
  robot.respond /(.*)(i am hungry|饿)(.*)/i, (msg) ->
    Dianping msg


Dianping = (msg) ->
  msg.http("http://api.dianping.com/v1/business/find_businesses?appkey=185566924&sign=BD7980DE89A2745EC951B1D8B67D851DABBAD62C&category=%E7%BE%8E%E9%A3%9F&city=%E5%B9%BF%E5%B7%9E&latitude=23.1244645696&longitude=113.3709396155&sort=1&limit=20&offset_type=1&out_offset_type=1&platform=2&radius=1000")
    .get() (err, res, body) ->
      res = JSON.parse body
      if res.total is 0
        msg.send "No results found for #{query}"
      else
        max = res.businesses.length
        index = Math.floor(Math.random() * (max))
        shopObj = res.businesses[index]
        shopName = shopObj.name.slice(0, shopObj.name.lastIndexOf "(")
        shopUrl = shopObj.business_url.replace /lite.m.dianping/, "www.dianping"
        msg.send "去#{shopName}吧\n距离#{shopObj.distance}米\n详情:#{shopUrl}"
        