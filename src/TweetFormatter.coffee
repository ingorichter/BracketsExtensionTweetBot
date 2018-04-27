###
 * TweetFormatter
 * http://github.com/ingorichter/BracketsExtensionTweetBot
 *
 * Copyright (c) 2014 Ingo Richter
 * Licensed under the MIT license.
###
# jslint vars: true, plusplus: true, devel: true, node: true, nomen: true, indent: 4, maxerr: 50

'use strict'

Formatter = require './Formatter'
_ = require 'lodash'
semver = require 'semver'

tweetRE = /^(.*)\s+-\s+(.+)\s+\(.+\)/

module.exports =
  class TweetFormatter extends Formatter
    formatTweet: (tweet) ->
      match = tweet.text.match tweetRE
      urls = tweet.entities.urls
      if urls.length == 2
        homePageURL = urls?[0].expanded_url
        downloadURL = urls?[1].expanded_url
      else
        homePageURL = downloadURL = urls?[0].expanded_url

      "|[#{match[1]}](#{homePageURL})|#{match[2]}|N/A|#{@formatUrl(downloadURL)}|"

    # Remove duplicates in the changeset
    removeDuplicatesFromChangeset: (changeSet) ->
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

      { "NEW": _.map(_.compact(newSet), (obj) -> obj.tweet), "UPDATE": _.map(updatedSet, (obj) -> obj.tweet) }

    transform: (changeSet) ->
      cleanedChangeSet = @removeDuplicatesFromChangeset changeSet
      # process all new extensions
      newTweets = (@formatTweet tweet for tweet in cleanedChangeSet["NEW"])
      updatedTweets = (@formatTweet tweet for tweet in cleanedChangeSet["UPDATE"])

      @formatResult newTweets, updatedTweets
