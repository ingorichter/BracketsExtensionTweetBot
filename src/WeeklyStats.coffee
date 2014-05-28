es = require './ExtensionStats'

es.extractChangesFromTweets(new Date(2014, 4, 26, 23, 0)).then (changeset) ->
  markdown = es.transformChangeset(changeset)
  console.log markdown