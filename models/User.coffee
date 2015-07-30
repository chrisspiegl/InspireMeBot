Sequelize = require 'sequelize'

User = sequelize.define('User', {
  id:
    type: Sequelize.INTEGER
    primaryKey: true
  first_name: Sequelize.STRING
  last_name: Sequelize.STRING
  username: Sequelize.STRING
  subscribed: Sequelize.BOOLEAN
  interval: Sequelize.INTEGER
  settings: Sequelize.TEXT
  timeZone: Sequelize.STRING
}, {
  classMethods: {}
  instanceMethods: {}
})

module.exports = User
