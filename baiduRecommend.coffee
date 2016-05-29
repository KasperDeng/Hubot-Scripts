# Description:
#   Allows Hubot to interact with baidu to recommandation.
#
# Commands:
#   hubot 推荐|列举 <地点> <关键字> - 由百度推荐1公里附近的
#

module.exports = (robot) ->
  robot.respond /(?:.*)(推荐|列举) (.*) (.*)/i, (msg) ->
    baiduRecommend msg


baiduRecommend = (msg) ->
  param =
    location: new Buffer msg.match[2]
    keyword: new Buffer msg.match[3]
    baiduAk: "" # Your baiduAk

  _getGeoLocation msg, param, _getBaiduRecommendation


_getGeoLocation = (msg, param, callback) ->
  baiduGeoCoderUrl = "http://api.map.baidu.com/geocoder/v2/?address=#{param.location}&output=json&ak=#{param.baiduAk}"
  req = msg.http baiduGeoCoderUrl
  req.get() (err, res, body) ->
    if res.statusCode isnt 200
        res.send "Response with HTTP #{res.statusCode} :("
        return

    jsonBody = JSON.parse body
    if jsonBody.status isnt 0
      msg.send "Failed to get the geo location. Please input in details!"
      return

    loc = jsonBody.result.location
    callback msg, param, loc

_getBaiduRecommendation = (args...) ->
  [msg, param, loc] = args
  baiduRecomUrl = "http://api.map.baidu.com/place/v2/search?query=#{param.keyword}&location=#{loc.lat},#{loc.lng}&scope=2&radius=1000&output=json&ak=#{param.baiduAk}"
  msg.http(baiduRecomUrl).get() (err, res, body) ->
    res = JSON.parse body
    if res.status is 0
      max = res.results.length
      if max isnt 0
        content = ""
        console.log msg.match[1]
        random = msg.match[1] is "推荐"
        if random
          index = Math.floor(Math.random() * (max))
          shop = res.results[index]
          content = _getRandomContent shop
        else
          content = _getContent res.results

        msg.send content
    else
      msg.send "No results found!"

_getRandomContent = (shop) ->
  shopName = shop.name
  shopAddress = shop.address
  shopContact = shop.telephone
  shopDetail = shop.detail_info
  shopDistance = shopDetail.distance
  shopTag = shopDetail.tag
  shopPrice= shopDetail.price
  shopRating = shopDetail.overall_rating
  shopSrvRating = shopDetail.service_rating
  shopEnvRating = shopDetail.environment_rating
  shopUrl = shopDetail.detail_url
  content = "** #{shopName} **\n"
  content += "距离: #{shopDistance}米\n" if shopDistance
  content += "电话：#{shopContact}\n" if shopContact
  content += "地址：#{shopAddress}\n" if shopAddress
  content += "标签：#{shopTag}\n" if shopTag
  content += "人均：¥#{shopPrice}\n" if shopPrice
  content += "评分：#{shopRating}\n" if shopRating
  content += "服务：#{shopSrvRating}\n" if shopSrvRating
  content += "环境：#{shopEnvRating}\n" if shopEnvRating
  content += "详情: #{shopUrl}" if shopUrl
  return content

_getContent = (results) ->
  content = ""
  for result in results
    content += "#{result.name}\n"
  return content
