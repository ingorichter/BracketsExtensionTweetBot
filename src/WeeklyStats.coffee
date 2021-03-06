es = require './ExtensionStats'
moment = require 'moment'

process.exit 1 if process.argv.length < 3

# expect argv[2] to be a date in the format mm/dd/yyyy, 11/27/2014
dateTo = moment(new Date(process.argv[3]))
dateTo.hours(2)
dateTo.minutes(0)
dateTo.seconds(0)

dateFrom = moment(dateTo)
dateFrom.subtract(7, 'days')
dateFrom.seconds(1)

# get all the tweets from
es.extractChangesFromRegistry(dateFrom.toDate(), dateTo.toDate()).then (changeset) ->
# es.extractChangesFromRegistry(new Date(2014, 10, 10, 2, 0, 1), new Date(2014, 10, 17, 2, 0, 0)).then (changeset) ->
  markdown = es.transfromRegistryChangeset(changeset)
  console.log markdown
