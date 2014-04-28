###
 * BracketsExtensionTweetBot
 * http://github.com/ingorichter/BracketsExtensionTweetBot
 *
 * Copyright (c) 2014 Ingo Richter
 * Licensed under the MIT license.
###
# jslint vars: true, plusplus: true, devel: true, node: true, nomen: true, indent: 4, maxerr: 50

'use strict'

promise = require 'bluebird'
Twit = require 'twit'

module.exports =
  class TwitterPublisher
    constructor: (config) ->
      @twitterClient = new Twit(config)

    post: (tweet) ->
      deferred = promise.defer()
      @twitterClient.post 'statuses/update', { status: tweet }, (err, reply, response) ->
        if err
          deferred.reject err
        else
          deferred.resolve reply

      deferred.promise

    userTimeLine: ->
      deferred = promise.defer()
      @twitterClient.get 'statuses/home_timeline', (err, reply, response) ->
        if err
          deferred.reject err
        else
          deferred.resolve reply

      deferred.promise

    search: (query, untilDate) ->
      deferred = promise.defer()
      
      options = {}
      options.q = query
      
      options.until = untilDate if untilDate

      @twitterClient.get 'search/tweets', options, (err, reply, response) ->
        if err
          deferred.reject err
        else
          deferred.resolve reply

      deferred.promise
