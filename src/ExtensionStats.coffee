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
semver = require 'semver'
fs = require 'fs'
Promise = require 'bluebird'
_ = require 'lodash'
TwitterPublisher = require './TwitterPublisher'

TWITTER_CONFIG = path.resolve(__dirname, '../twitterconfig.json')
twitterPublisher = undefined

# Constant
DEFAULT_NUMBER_OF_DAYS = 7
UPDATE_KEY = "UPDATE"
NEW_KEY = "NEW"
tweetRE = /^(.*)\s+-\s+(.+)\s+\(.+\)/

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

  deferred = Promise.defer()
  getTweetsFromRange(from, to).then (tweets) ->
    deferred.resolve tweets

  deferred.promise

extractChangesFromTweets = (from, to) ->
  deferred = Promise.defer()
  getTweets(from, to).then (tweets) ->
    cs = createChangeSet tweets
    deferred.resolve cs
    
  deferred.promise

search = (query, untilDate) ->
  # read twitter config file
  twitterConf = JSON.parse(fs.readFileSync(TWITTER_CONFIG))

  twitterPublisher = new TwitterPublisher(twitterConf)

  promise = twitterPublisher.search(query, untilDate)
  promise.then (data) ->
    fs.writeFileSync(path.resolve(__dirname, '../tweets.json'), JSON.stringify(data))
  promise.catch (err) ->
    console.log err

# Remove duplicate in the changeset
removeDuplicatesFromChangeset = (changeSet) ->
  makeObject = (tweet) ->
    match = tweet.text.match tweetRE
    {name: match[1], version: match[2], tweet: tweet}

  _removeDuplicates = (changeSet) ->
    resultSet = []
    for tweet in changeSet
      obj = makeObject tweet
      index = _.findIndex(resultSet, {name: obj.name})

      resultSet.push obj if index == -1
      resultSet[index] = obj if index > -1 && semver.gt(obj.version, resultSet[index].version)

    resultSet
    
  updatedSet = _removeDuplicates changeSet["UPDATE"]
  newSet = _removeDuplicates changeSet["NEW"]
  
  for tweet in updatedSet
    index = _.findIndex(newSet, {name: tweet.name})
    newSet[index] = false if index > -1
  
  {"NEW": _.map(_.compact(newSet), (obj) -> obj.tweet), "UPDATE": _.map(updatedSet, (obj) -> obj.tweet)}

transformChangeset = (changeSet) ->
  header = """
| Name | Version | Description | Download |
|------|---------|-------------|----------|
"""
  formatUrl = (url) ->
    "<a href=\"#{url}\"><div class=\"imageHolder\"><img src=\"images/cloud_download.svg\" class=\"image\"/></div></a>"

  formatTweet = (tweet) ->
    match = tweet.text.match tweetRE
    urls = tweet.entities.urls
    if urls.length == 2
      homePageURL = urls?[0].expanded_url
      downloadURL = urls?[1].expanded_url
    else
      homePageURL = downloadURL = urls?[0].expanded_url

    "|[#{match[1]}](#{homePageURL})|#{match[2]}|N/A|#{formatUrl(downloadURL)}|"

  cleanedChangeSet = removeDuplicatesFromChangeset changeSet
  # process all new extensions
  newTweets = (formatTweet tweet for tweet in cleanedChangeSet["NEW"])
  updatedTweets = (formatTweet tweet for tweet in cleanedChangeSet["UPDATE"])

  # format result
  result = ""
  result = "## New Extensions" + "\n" + header + "\n" + newTweets.join("\n") if newTweets.length
  result += "\n" if newTweets.length and updatedTweets.length
  result += "## Updated Extensions" + "\n" + header + "\n" + updatedTweets.join("\n") if updatedTweets.length

# API
exports.createChangeSet          = createChangeSet
exports.extractChangesFromTweets = extractChangesFromTweets
exports.getTweets                = getTweets
exports.search                   = search
exports.timeline                 = timeline
exports.transformChangeset       = transformChangeset