###

Description: Hey, I am the InspireMeBot. I am here to inspire you daily with new quotes! You can subscribe via /start and if you need some inspiration right now, just send /now and I will get you a quote in no time.
About: InspireMeBot will give you inspiring quotes on a daily basis. It is easy and uplifting!
###


async = require 'async'
_ = require 'lodash'
path = require 'path'
moment = require 'moment-timezone'
crypto = require 'crypto'
schedule = require 'node-schedule'

Bot = require 'telegram-api'
Message = require 'telegram-api/types/Message'
File = require 'telegram-api/types/File'
Question = require 'telegram-api/types/Question'
Keyboard = require 'telegram-api/types/Keyboard'
BulkMessage = require 'telegram-api/types/BulkMessage'

# ==============================================================================
root = path.resolve process.cwd()

config = require './config'

require './db'

console.log "STARTING #{new Date()}"

bot = new Bot({
  token: config.telegram.token
})

# ==============================================================================

Quote = require './models/Quote'
User = require './models/User'
Feedback = require './models/Feedback'

# ==============================================================================
# bot.start({
#   url: ''
#   port: 443
#   server: {}
# })

bot.start().catch((err) ->
  console.error err, '\n', err.stack
)

# ==============================================================================
bot.command 'now', (message) ->
  Quote.rand('Inspirational').then((quote) ->
    answer = new Message().text("""
    #{quote.text}
    ~ #{quote.author}
    """).to(message.chat.id)
    bot.send answer
  ).catch((err) ->
    throw err if err
  ).done()


# ==============================================================================
bot.command 'start', (message) ->
  console.log message
  console.log moment().toString()
  console.log moment.unix(message.date).toString()
  user = {
    id: message.chat.id
    first_name: message.chat.first_name
    last_name: message.chat.last_name
    username: message.chat.username
    subscribed: false
    interval: 1
    timeZone: 'Europe/Berlin'
  }
  async.waterfall [
    getUser = (callback) ->
      User.findOrCreate({where: {id: user.id}, defaults: user}).spread((user, created) ->
        return callback null, user.subscribed, created, user
      )
    setSubscribeSetting = (wasSubscribed, created, user, callback) ->
      return callback null, true, user.interval if wasSubscribed
      user.subscribed = true
      user.save({fields: ['subscribed']}).then(() ->
        return callback null, false, user.interval
      )
  ], (err, wasSubscribed, interval) ->
    throw err if err
    if wasSubscribed
      text = "You are already subscribed. To change the settings of your subscription please use the /settings command. If you want to stop receiving quotes just use the /stop command."
    else
      intervalText = switch interval
        when 1 then "one inspirational quote per day"
        when 2 then "two inspirational quotes per day"
        when 24 then "one inspirational quote every hour"
        else "#{interval} inspirational quotes per day"
      text = "You are now subscribed to get #{intervalText}. Hope you enjoy it :)."
    answer = new Message().text(text).to(message.chat.id)
    bot.send answer

# ==============================================================================
bot.command 'stop', (message) ->
  async.waterfall [
    getUser = (callback) ->
      User.findById(message.chat.id).then((user) ->
        return callback null, user
      )
    setSubscribeSetting = (user, callback) ->
      return callback null, false if user.subscribed is false
      user.subscribed = false
      user.save({fields: ['subscribed']}).then(() ->
        return callback null, true
      )
  ], (err, wasSubscribed) ->
    throw err if err
    if wasSubscribed
      text = "You are now unsubscribed. To subscribe to daily quotes again you can use /start or get some inspiration right /now - hope to give you some inspiration later on."
    else
      text = "You are not subscribed to my quotes. You can subscribe using /start or get some inspiration right /now."
    answer = new Message().text(text).to(message.chat.id)
    bot.send answer

# ==============================================================================
bot.command 'status', (message) ->
  async.waterfall [
    getUser = (callback) ->
      User.findById(message.chat.id).then((user) ->
        return callback null, user.subscribed, user.interval
      )
  ], (err, isSubscribed, interval) ->
    throw err if err
    if isSubscribed
      intervalText = switch interval
        when 1 then "one inspirational quote per day"
        when 2 then "two inspirational quotes per day"
        when 24 then "one inspirational quote every hour"
        else "#{interval} inspirational quotes per day"
      text = "You are currenlty subscribed. I will send you #{intervalText}."
    else
      text = "You are currently not subscribed and I will not send you inspirational quotes unless you request one with /now."
    answer = new Message().text(text).to(message.chat.id)
    bot.send answer

# ==============================================================================
answersSettings = [
  ['Interval', 'Time Zone']
]
answersSettingsFlat = _.flatten answersSettings
questionSettings = new Question().text('What settings do you want to change?').answers(answersSettings)
keyboardHide = new Keyboard().hide()

settings = (message) ->
  bot.send(questionSettings.to(message.chat.id)).then((answer) ->
    return settings(message) unless answer
    if answer?.text in answersSettingsFlat
      switch answer.text
        when 'Interval' then return settingsInterval(answer)
        when 'Time Zone' then return settingsTimeZone(answer)
    return settingsEnd(answer)
  )
questionSettingsInterval = new Question().text('How often do you want to be inspired [1-6] per day?').answers([['1','2'],['3', '4'], ['5', '6']])
settingsInterval = (message) ->
  bot.send(questionSettingsInterval.to(message.chat.id)).then((answer) ->
    interval = _.parseInt answer.text
    if interval and interval >= 1 and interval <= 6
      user = {
        id: answer.chat.id
        first_name: answer.chat.first_name
        last_name: answer.chat.last_name
        username: answer.chat.username
        subscribed: false
        interval: 1
        timeZone: 'Europe/Berlin'
      }
      User.findOrCreate({where: {id: user.id}, defaults: user}).spread((user, created) ->
        user.interval = interval
        user.save({fields:['interval']}).then((user) ->
          intervalText = switch user.interval
            when 1 then "once per day"
            when 2 then "twice per day"
            when 24 then "every hour of the day"
            else "#{user.interval} times per day"
          bot.send new Message().text("You will receive inspirational quotes #{intervalText} (Note that this will only happen if you subscribed via /start). I hope you enjoy them!").to(answer.chat.id).keyboard(keyboardHide)
        )
      )
    else
      return settingsInterval(answer)
  )

answerSettingsTimeZone = [
  'Europe/London',
  'Europe/Brussels',
  'Europe/Madrid',
  'Europe/Paris',
  'Europe/Rome',
  'Europe/Berlin',
  'Australia/Sydney',
  'Africa/Cairo',
  'Europe/Moscow',
  'Asia/Jakarta',
  'Asia/Hong_Kong',
  'Asia/Tokyo',
  'Australia/Melbourne',
  'America/Buenos_Aires',
  'America/New_York',
  'America/Mexico_City',
  'America/Los_Angeles',
]
_.each answerSettingsTimeZone, (name, key) ->
  answerSettingsTimeZone[key] = [name]
answerSettingsTimeZoneFlat = _.flatten answerSettingsTimeZone
questionSettingsTimeZone = new Question().text('What is your time zone?').answers(answerSettingsTimeZone)
settingsTimeZone = (message) ->
    bot.send(questionSettingsTimeZone.to(message.chat.id)).then((answer) ->
      timeZone = answer.text
      if timeZone in answerSettingsTimeZoneFlat
        user = {
          id: answer.chat.id
          first_name: answer.chat.first_name
          last_name: answer.chat.last_name
          username: answer.chat.username
          subscribed: false
          interval: 1
          timeZone: 'Europe/Berlin'
        }
        User.findOrCreate({where: {id: user.id}, defaults: user}).spread((user, created) ->
          user.timeZone = timeZone
          user.save({fields:['timeZone']}).then((user) ->
            bot.send new Message().text("Ok, I will set your timezone to be #{timeZone}. Your quotes will be delivered according to that.").to(answer.chat.id).keyboard(keyboardHide)
          )
        )
      else
        return settingsTimeZone(answer)
    )

settingsEnd = (message) ->
  bot.send new Message().to(message.chat.id).keyboard(keyboardHide)

bot.command 'settings', settings

# ==============================================================================
bot.command 'help', (message) ->
  bot.send new Message().text("""
  You need inspiration? I am your daily inspiration bot. You can set me up to send you a nice quote any time you want, or just request one right /now!

  You can control me by sending these commands:

  /now - Get a inspiring quote right now
  /start - Start receiving inspiring quotes
  /stop - Abort the subscription to the quotes
  /status - Show the status of your subscription and settings
  /settings - Change some settings (interval and timezone)
  /feedback <msg> - Send feedback about this bot to the developer
  /help - Show this help text
  """).to(message.chat.id)

# ==============================================================================
bot.command 'feedback ...feedback', (message) ->
  chat = message.chat
  text = message?.args?.feedback
  if text
    feedback = {
      author: JSON.stringify(chat)
      text: text
    }
    Feedback.create(feedback).then((feedback) ->
      bot.send new Message().text("""
      New Feedback from @#{chat.username} saved with Id #{feedback.id}:
      #{text}
      """).to(config.telegram.admin)
    )
    bot.send new Message().text('Thanks for your feedback. We have saved it and will try to improve soon :).').to(message.chat.id)
  else
    bot.send new Message().text('Please provide the feedback in the argument like the following: /feedback I really like InspireMeBot but I would like to see feature ...').to(message.chat.id)

# ==============================================================================
bot.on 'command-notfound', (message) ->
  if message.chat.id > 0 and message.text[0] is '/'
    bot.send new Message().text("""
    Sorry, I don't know what to do with this command.
    Please check /help to get ideas how to use me.
    """).to(message.chat.id)

# ==============================================================================
bot.on 'update', (update) ->
  console.log 'Polled\n\t', update

# ==============================================================================
# cronJob = schedule.scheduleJob('* * * * * *', () ->
cronJob = schedule.scheduleJob('0 0 * * * *', () ->
  async.eachLimit(answerSettingsTimeZoneFlat, 1, (timeZone, callback) ->
    console.log "Seinding Messages to #{timeZone}"
    hour = moment().tz(timeZone).hour()
    intervals = []
    # 1  17
    # 2  17 10
    # 3  17 10 13
    # 4  17 10 13 8
    # 5  17 10 13 8 20
    # 6  17 10 13 8 20 22
    if hour is 17
      intervals = _.union intervals, [1]
    if hour in [17, 10]
      intervals = _.union intervals, [2]
    if hour in [17, 10, 13]
      intervals = _.union intervals, [3]
    if hour in [17, 10, 13, 9]
      intervals = _.union intervals, [4]
    if hour in [17, 10, 13, 9, 20]
      intervals = _.union intervals, [5]
    if hour in [17, 10, 13, 9, 20, 22]
      intervals = _.union intervals, [6]

    User.findAll({where: {interval: intervals, timeZone: timeZone}}).then((users) ->
      userIds = _.pluck users, 'id'
      Quote.rand('Inspirational').then((quote) ->
        message = new BulkMessage().text("""
        #{quote.text}
        ~ #{quote.author}
        """).to(userIds)
        bot.send message
        console.log 'Sent Message - ', hour, ' tz ', timeZone,' to ', userIds
        callback null
      )
    )
  , (err) ->
    throw err if err
    console.log 'finished'
  )
)

console.log 'end of file'
