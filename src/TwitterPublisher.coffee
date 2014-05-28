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

    setClient: (client) ->
      @twitterClient = client

    post: (tweet) ->
      deferred = promise.defer()
      @twitterClient.post 'statuses/update', { status: tweet }, (err, reply, response) ->
        if err
          deferred.reject err
        else
          deferred.resolve reply

      deferred.promise

    # https://dev.twitter.com/docs/api/1.1/get/statuses/user_timeline
    # count - default is 20 defined by the twitter API
    # @param {?String} max_id - results lower or equal to max_id (to get older posts)
    userTimeLine: (max_id, count) ->
      deferred = promise.defer()
      
      options = {}
      options.max_id = max_id if max_id?
      options.count = count if count?

      @twitterClient.get 'statuses/home_timeline', options, (err, reply, response) ->
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
