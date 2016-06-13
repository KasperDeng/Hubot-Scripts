# Description:
#   Allows Hubot to interact with http://api.laifudao.com/open/xiaohua.json to get a joke.
#
# Commands:
#   hubot joke|"笑话" - make a joke to you|给你讲个笑话

module.exports = (robot) ->
  robot.respond /(?!turing)(?!图灵)(?:joke|笑话).*/i, (msg) ->
    makeJoke msg

makeJoke = (msg) ->
  req = msg.http("http://api.laifudao.com/open/xiaohua.json")
  req.header "Content-Type", "application/json;charset=UTF-8"
  req.header "Accept", "application/json"
  try
    req.get() (err, res, body) ->
      switch res.statusCode
        when 200
          jsonBody = eval body ## JSON.parse body - The return body is not comptibile
          randomIdx = Math.floor(Math.random() * 20)
          title = jsonBody[randomIdx].title
          content = jsonBody[randomIdx].content
          replyJoke = content.replace /(\<br\/\>\<br\/\>\s*)/g, "\n"
          msg.send "#{title}:\n #{replyJoke}"
        when 404
          msg.send "天下最大的笑话就是...，没笑话"
        else
          msg.send "Debug: #{res.statusCode}"
  catch
    console.log "Got error: ", error

