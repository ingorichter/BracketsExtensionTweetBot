es = require './ExtensionStats'

# get all the tweets from
es.extractChangesFromRegistry(new Date(2014, 10, 10, 2, 0, 1), new Date(2014, 10, 17, 2, 0, 0)).then (changeset) ->
  markdown = es.transfromRegistryChangeset(changeset)
  console.log markdown
