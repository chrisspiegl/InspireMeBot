Sequelize = require 'sequelize'

QuoteCategory = sequelize.define('QuoteCategory', {
  id:
    type: Sequelize.UUID
    defaultValue: Sequelize.UUIDV4
    primaryKey: true
  name: Sequelize.STRING
}, {
  classMethods: {}
  instanceMethods: {}
})

module.exports = QuoteCategory
