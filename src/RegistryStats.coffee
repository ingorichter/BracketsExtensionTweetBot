###
 * RegistryStats
 * http://github.com/ingorichter/BracketsExtensionTweetBot
 *
 * Copyright (c) 2014 Ingo Richter
 * Licensed under the MIT license.
###
# jslint vars: true, plusplus: true, devel: true, node: true, nomen: true, indent: 4, maxerr: 50
'use strict'

fs = require 'fs'
path = require 'path'
_ = require 'lodash'

if process.argv.length != 4
  console.log "Please provide registry to examine"
  process.exit 1

registry = JSON.parse(fs.readFileSync path.resolve(process.argv[3]))

console.log "Registry has #{Object.keys(registry).length} extensions"

#newExtensions = _.filter registryNew, (elem) ->
#  !_.filter(registryOld, elem.metadata.title)

# console.log newExtensions.length

tops = _.map registry, (extension) ->
  sum = _.reduce(extension.recent, (num, sum) ->
    sum + num
  name = extension.metadata.title
  t = {name: name, sum: sum}
  , 0)

top11Total = _.sortBy registry, 'totalDownloads'

f = (accu, extension) ->
  accu += extension.totalDownloads

totalDownloadsRegistry = _.reduce registry, f, 0

#console.log _.sortBy tops, "sum"
console.log "Total Downloads Registry #{totalDownloadsRegistry}"
console.log "Total Downloads:"
_.forEach top11Total, (extension) ->
  console.log "#{extension.metadata.name}: #{extension.totalDownloads}"

console.log "Extension Authors"
authors = []
_.forEach registry, (extension) ->
  authors.push extension.metadata.author if extension.metadata.author

authorNames = _.uniq _.map authors, (author) ->
  author.name

console.log "#{authorNames.length} Extension authors"
console.log authorNames
