# Description
#   Allows Hubot to interact with Douban to recommand movie.
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot recommend movie <query> - recommend a movie by Douban's rating
#   hubot 推荐电影 <query> - 根据豆瓣评分推荐电影
#


module.exports = (robot) ->
  robot.respond /(.*)(recommend movie|推荐电影)(.*)/i, (msg) ->
    Douban msg


Douban = (msg) ->
  msg.http("http://api.douban.com/v2/movie/search?tag=2015&count=50")
    .get() (err, res, body) ->
      res = JSON.parse body
      if res.total is 0
        msg.send "No results found."
      else
        max = res.subjects.length
        index = Math.floor(Math.random() * (max))
        shopObj = res.subjects[index]
        msg.send "去看<#{shopObj.title}>(#{shopObj.year})吧\n评分:#{shopObj.rating.average}\n详情:#{shopObj.alt}"