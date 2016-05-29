# Description:
#   Allows Hubot to remind you to do something.
#
# Commands:
#   hubot remind (action) time

cronJob = require('../node_modules/cron').CronJob
_ = require '../node_modules/underscore'


dayMap =
  "Sun": 0
  "Mon": 1
  "Tue": 2
  "Wed": 3
  "Thur": 4
  "Fri": 5
  "Sat": 6
  "sun": 0
  "mon": 1
  "tue": 2
  "wed": 3
  "thur": 4
  "fri": 5
  "sat": 6
  "Sunday": 0
  "Monday": 1
  "Tuesday": 2
  "Wednesday": 3
  "Thursday": 4
  "Friday": 5
  "Saturday": 6
  "sunday": 0
  "monday": 1
  "tuesday": 2
  "wednesday": 3
  "thursday": 4
  "friday": 5
  "saturday": 6
  "周日": 0
  "周一": 1
  "周二": 2
  "周三": 3
  "周四": 4
  "周五": 5
  "周六": 6
  "星期天": 0
  "星期一": 1
  "星期二": 2
  "星期三": 3
  "星期四": 4
  "星期五": 5
  "星期六": 6


module.exports = (robot) ->
  ## Check for actions that need to be fired, once a minute Monday to Friday.
  
  # http://crontab.org/
  # The time and date fields are:

  #   field          allowed values
  #   -----          --------------
  #   Seconds         0-59
  #   Minutes         0-59
  #   Hours           0-23
  #   Day of Month    1-31
  #   Months          0-11
  #   Day of Week     0-6
  findRoom = (msg) ->
    room = msg.envelope.room
  
    if _.isUndefined(room)
      room = msg.envelope.user.reply_to
  
    return room
  
  ## Returns just actions for a given room.
  getActionsForRoom = (room) ->
    return _.where(getActions(), {room: room})
  
  actionShouldFire = (action) ->
    actionDays = getDays action.day
    actionTime = action.time
    now = new Date()
  
    currentDay = now.getDay()
    currentHours = now.getHours()
    currentMinutes = now.getMinutes()
  
    actionHours = actionTime.split(':')[0]
    actionMinutes = actionTime.split(":")[1]
  
    try
      actionHours = parseInt actionHours, 10
      actionMinutes = parseInt actionMinutes, 10
    catch _error
      return false
  
    if (currentDay in actionDays && actionHours is currentHours && actionMinutes is currentMinutes)
      return true
  
    return false
  
  ## Fires the action message.
  doAction = (action) ->
    robot.messageRoom action.room, action.action
  
  ## Gets all actions, fires ones that should be.
  checkActions = () ->
    actions = getActions()
    bbb = _.chain(actions).filter(actionShouldFire).each(doAction)
  
  ## Returns all actions.
  getActions = () ->
    return robot.brain.get("actions") || []
  
  updateBrain = (actions) ->
    robot.brain.set "actions", actions
  
  ## Stores an action in the brain.
  saveAction = (room, day, time, action) ->
    actions = getActions()
  
    newAction =
      day: day, 
      time: time,
      room: room,
      action: action
  
    actions.push newAction
    updateBrain actions
  
  clearSpecificActionForRoom = (room, day, time) ->
    actions = getActions()
    actionsToKeep = _.reject actions, {room: room, time:time, day: day}

    updateBrain actionsToKeep
    return actions.length - actionsToKeep.length

  getDays = (day) ->
    dayRange = [0, 1, 2, 3, 4, 5, 6]
    days = []

    if "-" in day
      start = dayMap[day.split('-')[0]]
      end = dayMap[day.split('-')[1]]
      if start < end
        days = dayRange[start..end]
      else if start is end
        days = dayRange
      else
        if end isnt 0   
          days = dayRange[(end-start)..]
          days = (days.concat dayRange[..end]).sort()
        else
          days = dayRange[start..]
          days.push end
          days = days.sort()
    else
      days.push dayMap[day]

    return days

  try
    new cronJob "1 * * * * *", checkActions, null, true
  catch ex
    console.log "cron pattern not valid"

  robot.respond /(remind|提醒) (?:"|“)(.*)(?:"|”) (.*) ((?:[01]?[0-9]|2[0-4]):[0-5]?[0-9])$/i, (msg) ->
    remind = msg.match[1]
    action = msg.match[2]
    day = msg.match[3]
    time = msg.match[4]
    console.log "action: #{action}, day: #{day}, time: #{time}"
    room = findRoom msg
    days = getDays(day)

    saveAction room, day, time, action
    msg.send "OK! #{remind} #{action} #{day} #{time}"

  robot.respond /(list actions|已有提醒)$/i, (msg) ->
    isEn = msg.match[1] is "list actions"
    actions = getActionsForRoom findRoom(msg)

    if actions.length is 0
      if isEn
        msg.send "Well this is awkward. You haven't got any remind actions set :-/"
      else
        msg.send "你还没有创建任何提醒。"
    else
      if isEn
        remindPrefix = "Your remind:"
      else
        remindPrefix = "你有提醒："

      actionsText = [remindPrefix].concat(_.map(actions, (action) ->
                             return "#{action.day} #{action.time} \"#{action.action}\""))
      msg.send actionsText.join("\n")

  robot.respond /(delete|删除) (.*) ([0-5]?[0-9]:[0-5]?[0-9])/i, (msg) ->
    isEn = msg.match[1] is "delete"
    day  = msg.match[2]
    time = msg.match[3]
    actionsCleared = clearSpecificActionForRoom findRoom(msg), day, time
    
    if actionsCleared is 0
      if isEn
        msg.send "Nice try. You don't even have an action at #{time}"
      else
        msg.send "你还没有创建提醒在#{day} #{time}呢！"
    else
      if isEn
        msg.send "Deleted your #{day} #{time} action."
      else
        msg.send "已删除#{day} #{time}的提醒。"
