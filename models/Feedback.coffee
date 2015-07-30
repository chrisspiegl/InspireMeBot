Sequelize = require 'sequelize'

Feedback = sequelize.define('Feedback', {
  id:
    type: Sequelize.UUID
    defaultValue: Sequelize.UUIDV4
    primaryKey: true
  author: Sequelize.TEXT
  text: Sequelize.TEXT
}, {
  classMethods: {}
  instanceMethods: {}
})

module.exports = Feedback
