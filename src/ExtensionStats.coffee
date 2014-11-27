###
 * BracketsExtensionTweetBot
 * http://github.com/ingorichter/BracketsExtensionTweetBot
 *
 * Copyright (c) 2014 Ingo Richter
 * Licensed under the MIT license.
###
# jslint vars: true, plusplus: true, devel: true, node: true, nomen: true, indent: 4, maxerr: 50

'use strict'

path = require 'path'
fs = require 'fs'
Promise = require 'bluebird'
request = require 'request'
zlib = require 'zlib'
TwitterPublisher = require './TwitterPublisher'
TweetFormatter = require './TweetFormatter'
RegistryFormatter = require './RegistryFormatter'
_ = require 'lodash'

TWITTER_CONFIG = path.resolve(__dirname, '../twitterconfig.json')
twitterPublisher = undefined

# Constant
DEFAULT_NUMBER_OF_DAYS = 7
UPDATE_KEY = "UPDATE"
NEW_KEY = "NEW"

REGISTRY_BASEURL = 'https://s3.amazonaws.com/extend.brackets'
BRACKETS_REGISTRY_JSON = "#{REGISTRY_BASEURL}/registry.json"

class DateRange
  constructor: (@from, @to) ->

  contains: (date) ->
    @from.getTime() <= date.getTime() <= @to.getTime()

downloadExtensionRegistry = ->
  deferred = Promise.defer()

  request {uri: BRACKETS_REGISTRY_JSON, json: true, encoding: null}, (err, resp, body) ->
    if err
      deferred.reject err
    else
      zlib.gunzip body, (err, buffer) ->
        if err
          console.error err
          deferred.reject err
        else
          deferred.resolve(JSON.parse(buffer.toString()))

  deferred.promise

createChangeSet = (tweets) ->
  newExtensions = (tweet for tweet in tweets when tweet.text.indexOf("(NEW)") > -1)
  updatedExtensions = (tweet for tweet in tweets when tweet.text.indexOf("(UPDATE)") > -1)
  {"NEW": newExtensions, "UPDATE": updatedExtensions }

timeline = (max_id, count) ->
  deferred = Promise.defer()

  promise = twitterPublisher.userTimeLine(max_id, count)
  promise.then (data) ->
    deferred.resolve data
  promise.catch (err) ->
    deferred.reject err

  deferred.promise

getTweetsFromRange = (endDate, numberOfDays) ->
  deferred = Promise.defer()
  # Range is [endDate - numberOfDays, endDate]
  # while if date of last tweet > (startDate - numberOfDays)
  # get a list of tweets
  # Build a date range [startDate...endDate]
  endDate = new Date(Date.now()) if not endDate
  endDate = endDate.getTime()

  numberOfDays = numberOfDays || DEFAULT_NUMBER_OF_DAYS

  startDate = endDate - (numberOfDays * 24 * 60 * 60 * 1000)
  lastTweetDate = endDate

  allTweets = []
  _tweets = (max_id, count) ->
    promise = timeline(max_id, count)
    promise.then (tweets) ->
      # console.log("Tweet creation date #{tweets[tweets.length - 1].created_at}")
      lastTweetDate = new Date(tweets[tweets.length - 1].created_at).getTime()

      if lastTweetDate > startDate
        allTweets.push tweet for tweet in tweets
        _tweets(tweets[tweets.length - 1].id, count)
      else
        allTweets.push tweet for tweet in tweets when new Date(tweet.created_at).getTime() > startDate
        deferred.resolve allTweets

  _tweets()

  deferred.promise

# return raw tweets for a specific range
#
getTweets = (from, to) ->
  # read twitter config file
  twitterConf = JSON.parse(fs.readFileSync(TWITTER_CONFIG))

  twitterPublisher = new TwitterPublisher(twitterConf)

  getTweetsFromRange(from, to)

getJSON = ->
  new Promise (resolve, reject) ->
    p = downloadExtensionRegistry()
    p.then (json) ->
      resolve json
    p.catch (err) ->
      reject err

filter = (from, to, json) ->
  to ?= new Date()
  filteredRegistry = _.filter json, (item) ->
    versions = item.versions.length
    pubDate = new Date(item.versions[versions - 1].published).getTime()
    pubDate >= from.getTime() && pubDate <= to.getTime()
#    console.log "#{item.metadata.title}-#{versions}-#{pubDate}"

  filteredRegistry

createChangeSetFromRegistry = (registry) ->
  newExtensions = _.filter registry, (extension) ->
    extension.versions.length == 1

  updatedExtensions = _.filter registry, (extension) ->
    extension.versions.length != 1

  console.warn "Mismatch" if (newExtensions.length + updatedExtensions.length) != registry.length
  {"NEW": newExtensions, "UPDATE": updatedExtensions}

filterRegistry = (from, to) ->
  new Promise (resolve, reject) ->
    getJSON().then (json) ->
      resolve filter(from, to, json)

extractChangesFromTweets = (from, to) ->
  new Promise (resolve, reject) ->
    getTweets(from, to).then (tweets) ->
      cs = createChangeSet tweets
      resolve cs
#  deferred = Promise.defer()
#  getTweets(from, to).then (tweets) ->
#    cs = createChangeSet tweets
#    deferred.resolve cs
#
#  deferred.promise

extractChangesFromRegistry = (from, to) ->
  filterRegistry(from, to).then (filteredRegistry) ->
    createChangeSetFromRegistry filteredRegistry

search = (query, untilDate) ->
  # read twitter config file
  twitterConf = JSON.parse(fs.readFileSync(TWITTER_CONFIG))

  twitterPublisher = new TwitterPublisher(twitterConf)

  promise = twitterPublisher.search(query, untilDate)
  promise.then (data) ->
    fs.writeFileSync(path.resolve(__dirname, '../tweets.json'), JSON.stringify(data))
  promise.catch (err) ->
    console.log err

transformChangeset = (changeSet) ->
  formatter = new TweetFormatter()
  formatter.transform changeSet

transfromRegistryChangeset = (changeSet) ->
  formatter = new RegistryFormatter()
  formatter.transform changeSet

# API
exports.createChangeSet            = createChangeSet
exports.createChangeSetFromRegistry= createChangeSetFromRegistry
exports.extractChangesFromTweets   = extractChangesFromTweets
exports.extractChangesFromRegistry = extractChangesFromRegistry
exports.filterRegistry             = filterRegistry
exports.getTweets                  = getTweets
exports.getJSON                    = getJSON
exports.search                     = search
exports.timeline                   = timeline
exports.transformChangeset         = transformChangeset
exports.transfromRegistryChangeset = transfromRegistryChangeset
