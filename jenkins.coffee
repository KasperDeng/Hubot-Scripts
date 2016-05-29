# Description:
#   Interact with your Jenkins CI server
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_JENKINS_URL
#   HUBOT_JENKINS_AUTH
#
#   Auth should be in the "user:password" format.
#
# Commands:
#   hubot ci b <jobNum> - builds by job number which from hubot ci list <filter>
#   hubot ci build <job> or unstable - builds specified job name or unstable list job
#   hubot ci list <filter> - lists Jenkins jobs, filter e.g. name&status&other
#   hubot ci describe <job> - Describes the specified Jenkins job
#   hubot ci last <job> - Details of the last build
#   hubot ci status <view> - List the overall status by overview

#
# Author:
#   dougcole
#   eyinsma add status..

querystring = require 'querystring'
yaml = require './node_modules/js-yaml/lib/js-yaml.js'
fs   = require 'fs'
jenkinsConfig = fs.readFileSync './scripts/unstablejob.yaml' , 'utf8'
jenkinsYamlConfig = yaml.load jenkinsConfig

# Holds a list of jobs, so we can trigger them with a number
# instead of the job's name. Gets populated on when calling
# list.
jobList = []

jenkinsBuildById = (msg) ->
  # Switch the index with the job name
  job = jobList[parseInt(msg.match[1]) - 1]

  if job
    msg.match[1] = job
    _jenkinsBuild(msg)
  else
    msg.reply "I couldn't find that job. Try `ci list` to get a list."

jenkinsBuild = (msg) ->
  job = querystring.escape msg.match[1]

  if job is "unstable"
    _jenkinsBuildUnstableJob msg
  else
    _jenkinsBuildByJobName msg

_jenkinsBuildByJobName = (msg) ->
  url = process.env.HUBOT_JENKINS_URL
  job = querystring.escape msg.match[1]
  path = "#{url}/job/#{job}/lastBuild/api/json"

  req = msg.http(path)

  _addJenkinsAuthToReq req

  req.header('Content-Length', 0)
  req.get() (err, res, body) ->
    switch res.statusCode
      when 200
        try
          content = JSON.parse body
          if content.building
            msg.send "The job is building"
            return
          else
            params = _getBuildParams content
            _jenkinsBuild msg, params, job
        catch error
          console.log "[getBuildParams] #{error}"
      when 404
        msg.send "job invalid: #{res.statusCode}"
      else
        msg.send "Debug: #{res.statusCode}"

_jenkinsBuildUnstableJob = (msg) ->
  url = process.env.HUBOT_JENKINS_URL
  for job in jenkinsYamlConfig.unstableJobList
    path = "#{url}/job/#{job}/lastBuild/api/json"

    req = msg.http(path)

    _addJenkinsAuthToReq req

    req.header 'Content-Length', 0
    req.get() (err, res, body) ->
      switch res.statusCode
        when 200
          try
            content = JSON.parse body
            if not content.building and content.result isnt "SUCCESS" #UNSTABLE FAILURE NOT_BUILT ABORTED
              re = /\s#[0-9]+/
              unstableJob = content.fullDisplayName.replace re, ''
              params = _getBuildParams content
              _jenkinsBuild msg, params, unstableJob
          catch error
            console.log "[getBuildParams] #{error}"
        when 404
          msg.send "job invalid: #{res.statusCode}"
        else
          msg.send "Debug: #{res.statusCode}"
        
_getBuildParams = (content) ->
  params = ""
  for action in content.actions
    if action.hasOwnProperty "parameters"
      for parameter in action.parameters
        if parameter.hasOwnProperty "name"
          if parameter.name is "goals"
            paramsValue = parameter.value
      paramsValueJson = JSON.parse paramsValue
      paramsValueJson2 = JSON.parse paramsValueJson
      for key, value of paramsValueJson2
        params += "#{key}=#{value}&"
      params = params.substring(0, params.length - 1)
  return params

_jenkinsBuild = (msg, params, job) ->
  url = process.env.HUBOT_JENKINS_URL
  path = if params then "#{url}/job/#{job}/buildWithParameters?#{params}" else "#{url}/job/#{job}/build"

  req = msg.http(path)

  _addJenkinsAuthToReq req

  req.header('Content-Length', 0)
  req.post() (err, res, body) ->
    if err
      msg.reply "Jenkins says: #{err}"
    else if 200 <= res.statusCode < 400 # Or, not an error code.
      #msg.reply "(#{res.statusCode}) Build started for #{job} #{url}/job/#{job}"
      msg.reply "(#{res.statusCode}) Build started for #{job}"
    else if 400 == res.statusCode
      msg.reply "Build not found."
    else if 404 == res.statusCode
      msg.reply "Build not found, double check that it exists and is spelt correctly."
    else
      msg.reply "Jenkins says: Status #{res.statusCode} #{body}"

jenkinsDescribe = (msg) ->
  url = process.env.HUBOT_JENKINS_URL
  job = msg.match[1]
  path = "#{url}/job/#{job}/api/json"
  req = msg.http(path)

  _addJenkinsAuthToReq req

  req.header('Content-Length', 0)
  req.get() (err, res, body) ->
    if err
      msg.send "Jenkins says: #{err}"
    else
      response = ""
      try
        content = JSON.parse(body)
        response += "JOB: #{content.displayName}\n"
        response += "URL: #{content.url}\n"
        if content.description
          response += "DESCRIPTION: #{content.description}\n"
        response += "ENABLED: #{content.buildable}\n"
        response += "STATUS: #{content.color}\n"
        tmpReport = ""
        if content.healthReport.length > 0
          for report in content.healthReport
            tmpReport += "\n  #{report.description}"
        else
          tmpReport = " unknown"
        response += "HEALTH: #{tmpReport}\n"
        parameters = ""
        for item in content.actions
          if item.parameterDefinitions
            for param in item.parameterDefinitions
              tmpDescription = if param.description then " - #{param.description} " else ""
              tmpDefault = if param.defaultParameterValue then " (default=#{param.defaultParameterValue.value})" else ""
              parameters += "\n  #{param.name}#{tmpDescription}#{tmpDefault}"
        if parameters != ""
          response += "PARAMETERS: #{parameters}\n"
        msg.send response
        if not content.lastBuild
          return
        path = "#{url}/job/#{job}/#{content.lastBuild.number}/api/json"
        req = msg.http(path)

        _addJenkinsAuthToReq req

        req.header('Content-Length', 0)
        req.get() (err, res, body) ->
          if err
            msg.send "Jenkins says: #{err}"
          else
            response = ""
            try
              content = JSON.parse(body)
              console.log(JSON.stringify(content, null, 4))
              jobstatus = content.result || 'PENDING'
              jobdate = new Date(content.timestamp)
              response += "LAST JOB: #{jobstatus}, #{jobdate}\n"
              msg.send response
            catch error
              msg.send error
      catch error
        msg.send error

jenkinsLast = (msg) ->
  url = process.env.HUBOT_JENKINS_URL
  job = msg.match[1]
  job = job.toLowerCase()
  path = "#{url}/job/#{job}/lastBuild/api/json"
  req = msg.http(path)

  _addJenkinsAuthToReq req

  req.header('Content-Length', 0)
  req.get() (err, res, body) ->
    if err
      msg.send "Jenkins says: #{err}"
    else
      try
        content = JSON.parse body
        response = "NAME: #{content.fullDisplayName}\n"
        #response += "URL: #{content.url}\n"
        if content.description
          response += "DESCRIPTION: #{content.description}\n"

        response += "BUILDING: #{content.building}\n"

        if not content.building
          response += "RESULT: #{content.result}\n"
        for action in content.actions
          if action.hasOwnProperty "causes"
            for cause in action.causes
              if cause.hasOwnProperty "shortDescription"
                response += "SHORT-DESCRIPTION: #{cause.shortDescription}"

        msg.send response
      catch error
        console.log "[jenkinsLast] #{error}"

jenkinsList = (msg) ->
  url = process.env.HUBOT_JENKINS_URL
  patterns = []
  filters = []

  if msg.match[2]?
    patterns = msg.match[2].split("&")
  for pattern in patterns
    filters.push(new RegExp(pattern, 'i'))

  req = msg.http("#{url}/api/json")

  _addJenkinsAuthToReq req

  req.get() (err, res, body) ->
    response = ""
    if err
      msg.send "Jenkins says: #{err}"
    else
      try
        content = JSON.parse(body)
        for job in content.jobs
          # Add the job to the jobList
          index = jobList.indexOf(job.name)
          if index == -1
            jobList.push(job.name)
            index = jobList.indexOf(job.name)
          if job.color == "red"
            state = "fail"
          else if job.color == "yellow"
            state = "partial_fail"
          else
            state = "pass"
          tempJobName = job.name + state
          ifListed = true
          for filter in filters
            if !(filter.test tempJobName)
              ifListed = false
              break
          if ifListed
            response += "[#{index + 1}] #{state} #{job.name}\n"
        msg.send response
      catch error
        msg.send error

jenkinsStatus = (msg) ->
  url = process.env.HUBOT_JENKINS_URL
  viewName = if msg.match[2]? then msg.match[2] else "All"

  if viewName is "sherlock" or viewName is "master"
    viewName = "master/view/sherlock"

  req = msg.http("#{url}/view/#{viewName}/api/json")

  _addJenkinsAuthToReq req

  req.get() (err, res, body) ->
    if err
      msg.send "Jenkins says: #{err}"
    else
      try
        content = JSON.parse body
        totalLen = content.jobs.length
        if totalLen <= 0
          msg.send "Oops, no content in that view:#{viewName}"
        else
          redList = []
          yellowList = []
          buildingList = []
          redNum = 0
          yellowNum = 0
          blueNum = 0
          abortedNum = 0
          buildingNum = 0
          maxDisplayNum = 10
          for job in content.jobs
            if job.color is "red" or job.color is "red_anime"
              redList.push job.name if redNum < maxDisplayNum
              redNum++
            if job.color is "yellow" or job.color is "yellow_anime"
              yellowList.push job.name if yellowNum < maxDisplayNum
              yellowNum++
            if job.color is "blue" or job.color is "blue_anime"
              blueNum++
            if job.color is "aborted" or job.color is "aborted_anime"
              abortedNum++
            if job.color is "red_anime" or job.color is "yellow_anime" or job.color is "blue_anime" or job.color is "aborted_anime"
              buildingList.push job.name if buildingNum < maxDisplayNum
              buildingNum++

          passrate = Math.round(blueNum / (redNum + yellowNum + blueNum + abortedNum) * 100)
          response = "Passrate:#{passrate}%\n"

          response += "[Sob]:#{redList.length}\n"
          while redList.length
            response += "  - #{redList.shift()}\n"

          response += "[Frown]:#{yellowList.length}\n"
          while yellowList.length
            response += "  - #{yellowList.shift()}\n"

          response += "[Grin]: #{blueNum}\n\n"

          response += "Building Job:#{buildingList.length}\n"
          while buildingList.length
            response += "  - #{buildingList.shift()}\n"

          msg.send response

      catch error
        msg.send error

_addJenkinsAuthToReq = (req) ->
  if process.env.HUBOT_JENKINS_AUTH
    auth = new Buffer(process.env.HUBOT_JENKINS_AUTH).toString 'base64'
    req.headers Authorization: "Basic #{auth}"

module.exports = (robot) ->
  robot.respond /c(?:i)? help( (.+))?/i, (msg) ->
    msg.reply "hubot ci b <jobNumber>\n
      hubot ci build <job>\n
      hubot ci build <job>, <params>\n
      hubot ci list <filter>\n
      hubot ci describe <job>\n
      hubot ci last <job>\n
      hubot ci status <view>\n"

  robot.respond /c(?:i)? build ([\w\.\-_ ]+)(, (.+))?/i, (msg) ->
    jenkinsBuild(msg)

  robot.respond /c(?:i)? b (\d+)/i, (msg) ->
    jenkinsBuildById(msg)

  robot.respond /c(?:i)? list (.*)/i, (msg) ->
    jenkinsList(msg)

  robot.respond /c(?:i)? describe (.*)/i, (msg) ->
    jenkinsDescribe(msg)

  robot.respond /c(?:i)? last (.*)/i, (msg) ->
    jenkinsLast(msg)

  robot.respond /c(?:i)? status( (.+))?/i, (msg) ->
    jenkinsStatus(msg)

  robot.jenkins = {
    list: jenkinsList,
    build: jenkinsBuild
    describe: jenkinsDescribe
    last: jenkinsLast
    status: jenkinsStatus
  }
