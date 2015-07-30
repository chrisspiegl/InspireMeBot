Sequelize = require 'sequelize'

Quote = sequelize.define('Quote', {
  id:
    type: Sequelize.UUID
    defaultValue: Sequelize.UUIDV4
    primaryKey: true
  author: Sequelize.STRING
  category: Sequelize.STRING
  text: Sequelize.TEXT
}, {
  classMethods: {
    rand: (category) ->
      return Quote.findOne({where: {category: category}, order:[Sequelize.fn('RANDOM')]}) # 'RANDOM' might need to be changed to 'RAND' for other db solutions than sqlite
  }
  instanceMethods: {}
})

module.exports = Quote
