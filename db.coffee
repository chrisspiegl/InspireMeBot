Sequelize = require 'sequelize'
global.sequelize = sequelize = new Sequelize('InspireMeBot', 'InspireMeBot', 'InspireMeBot', {
  dialect: 'sqlite'
  storage: "./storage/database.sqlite"
  logging: false
})

sequelize
  .authenticate()
  .then(() ->
    console.log 'DB: Connection has been established successfully.'

    User = require './models/User'
    Quote = require './models/Quote'
    QuoteCategory = require './models/QuoteCategory'
    Feedback = require './models/Feedback'

    sequelize.sync().then(() ->
      console.log 'DB: Sync - not forced - Worked!'
      # NOTE: This db-setup.coffee is setting up basic users and is thus not tracked (there might be passwords)!
      require './db-setup.coffee'
    ).catch((err) ->
      throw err if err
    ).done()
  ).catch((err) ->
    throw err if err
  ).done()
