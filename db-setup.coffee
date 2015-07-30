Quote = require './models/Quote'
QuoteCategory = require './models/QuoteCategory'

_ = require 'lodash'
fs = require 'fs'
async = require 'async'
parse = require 'csv-parse'
parser = parse({delimiter: ';'}, (err, data) ->
  quoteCategories = []
  async.eachLimit(data, 5, (quote, callback) ->
    quoteDb = {
      text: quote[0]
      author: quote[1]
      category: quote[2]
    }
    if quoteDb.text isnt 'QUOTE' and quoteDb.author isnt 'AUTHOR'
        quoteDb.category = quoteDb.category.charAt(0).toUpperCase() + quoteDb.category.slice(1)
        quoteCategories = _.union quoteCategories, [quoteDb.category]
        # console.log 'will create quote '
        Quote.create(quoteDb).then(() ->
          # console.log 'created quote '
        ).catch((err) ->
          return callback err
        ).done(() ->
          return callback null
        )
    else
      return callback null
  , (err) ->
    throw err if err
    async.eachLimit(quoteCategories, 5, (category, callback) ->
      QuoteCategory.create({name: category}).done(() ->
        return callback null
      )
    , (err) ->
      throw err if err
    )
  )
)
parser.on('finish', () ->
)
parser.on('error', (err) ->
  console.log err.message
)

Quote.count().then((count) ->
  if count is 0
    console.log 'reading CSV quotes into database'
    fs.createReadStream(__dirname + '/storage/quotes_all.csv').pipe(parser)
  else
    console.log 'quotes are already int he database'
)
