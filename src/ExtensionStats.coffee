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
#fs = promise.promisifyAll(require 'fs')
fs = require 'fs'
Promise = require 'bluebird'
TwitterPublisher = require './TwitterPublisher'

TWITTER_CONFIG = path.resolve(__dirname, '../twitterconfig.json')

extractTweets = (tweets) ->
  console.log "retrieved #{tweets.length} tweets"
  console.log "last tweets from #{tweets[tweets.length - 1].created_at}"

timeline = (max_id) ->
  deferred = Promise.defer()

  # read twitter config file
  twitterConf = JSON.parse(fs.readFileSync(TWITTER_CONFIG))

  twitterPublisher = new TwitterPublisher(twitterConf)

  promise = twitterPublisher.userTimeLine(max_id)
  promise.then (data) ->
#    fs.writeFileSync(path.resolve(__dirname, '../tweets.json'), JSON.stringify(data))
    extractTweets data
    deferred.resolve data
  promise.catch (err) ->
    deferred.reject err

  deferred.promise

getTweetsFromRange = (endDate, numberOfDays) ->
  deferred = Promise.defer()
  # Range is [endDate - numberOfDays, endDate]
  # while if date of last tweet > (startDate - numberOfDays)
  # get a list of tweets
  
  endDate = new Date() if not startDate
  endDate = endDate.getTime()

  numberOfDays ?= 7

  startDate = endDate - (numberOfDays * 24 * 60 * 60 * 1000)
  lastTweetDate = endDate
  # new Date(d.getTime() - (7 * 24 * 60 * 60 * 1000))

  allTweets = []
  
  _tweets = (max_id) ->
    promise = timeline(max_id)
    promise.then (tweets) ->
      lastTweetDate = new Date(tweets[tweets.length - 1].created_at).getTime()
      allTweets.push tweet for tweet in tweets
      if lastTweetDate > startDate
        _tweets tweets[tweets.length - 1].id
      else
        deferred.resolve allTweets

  _tweets()

  deferred.promise

getTweets = ->
  getTweetsFromRange(new Date(), 7).then (tweets) ->
    console.log "Got #{tweets.length} for the last 7 days"

search = (query, untilDate) ->
  # read twitter config file
  twitterConf = JSON.parse(fs.readFileSync(TWITTER_CONFIG))

  twitterPublisher = new TwitterPublisher(twitterConf)

  promise = twitterPublisher.search(query, untilDate)
  promise.then (data) ->
    fs.writeFileSync(path.resolve(__dirname, '../tweets.json'), JSON.stringify(data))
  promise.catch (err) ->
    console.log err
  # API

exports.search = search
exports.getTweets = getTweets
exports.timeline = timeline