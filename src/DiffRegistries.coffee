###
 * DiffRegistries
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

if process.argv.length != 5
  console.log "Please provide old and new registry to compare"
  process.exit 0

registryOld = JSON.parse(fs.readFileSync path.resolve(process.argv[3]))
registryNew = JSON.parse(fs.readFileSync path.resolve(process.argv[4]))

console.log "Old Registry has #{Object.keys(registryOld).length} elements"
console.log "New Registry has #{Object.keys(registryNew).length} elements"

#newExtensions = _.filter registryNew, (elem) ->
#  !_.filter(registryOld, elem.metadata.title)

# console.log newExtensions.length

tops = _.map registryNew, (extension) ->
  sum = _.reduce extension.recent, (num, sum) ->
    sum + num
  name = extension.metadata.title
  t = {name: name, sum: sum}

top10Total = _.sortBy(registryNew, 'totalDownloads').reverse()

f = (accu, extension) ->
  dl = extension.totalDownloads ? 0
  accu += dl

totalDownloadsOldRegistry = _.reduce registryOld, f, 0
totalDownloadsNewRegistry = _.reduce registryNew, f, 0

#console.log _.sortBy tops, "sum"
console.log "Total Downloads Old Registry #{totalDownloadsOldRegistry}"
console.log "Total Downloads New Registry #{totalDownloadsNewRegistry}"
console.log "New downloads: #{totalDownloadsNewRegistry - totalDownloadsOldRegistry}"
console.log "Total Downloads:"
_.forEach top10Total, (extension) ->
  console.log "#{extension.metadata.name}: #{extension.totalDownloads}"

console.log "Extension Authors"
authors = []
_.forEach registryNew, (extension) ->
  authors.push extension.metadata.author if extension.metadata.author

authorNames = _.uniq _.map authors, (author) ->
  author.name

console.log "#{authorNames.length} Extension authors"
console.log authorNames
