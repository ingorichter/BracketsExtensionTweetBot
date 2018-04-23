###
 * ExtensionStats
 * http://github.com/ingorichter/BracketsExtensionTweetBot
 *
 * Copyright (c) 2014 Ingo Richter
 * Licensed under the MIT license.
###

'use strict'

path    = require 'path'
_       = require 'lodash'
Promise = require 'bluebird'
fs      = Promise.promisifyAll require 'fs'

p = fs.readFileAsync path.resolve(path.join module.id, 'registry-last-sunday.json')

p.then (json) ->
  JSON.parse json
.then (registry) ->
  allThemes = _.filter registry, (extension) -> extension.metadata.theme?
  allExtensions = _.filter registry, (extension) -> !extension.metadata.theme?

  predicate = (extension) ->
    sum = _.reduce extension.recent, (num, sum) ->
      sum + num
    t = {name: extension.metadata.title, sum: sum ? 0}

  topExtensions = _.map allExtensions, predicate
  topThemes = _.map allThemes, predicate

#  list = '<% _.forEach(extensions, function(extension) { %>|<%= extension.name %>|<%= extension.sum %>|\n<% }); %>'
#  console.log _.template list, { 'extensions': _.first((_.sortBy topExtensions, "sum").reverse(), 11) }
#  console.log _.template list, { 'extensions': _.first((_.sortBy topThemes, "sum").reverse(), 11) }
  compiled = _.template '<% _.forEach(extensions, function(extension) { %>|<%= extension.name %>|<%= extension.sum %>|\n<% }); %>'
  console.log compiled { 'extensions': _.slice((_.sortBy topExtensions, "sum").reverse(), 0, 11) }
  console.log compiled { 'extensions': _.slice((_.sortBy topThemes, "sum").reverse(), 0, 11) }
