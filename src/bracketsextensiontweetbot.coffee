###
 * BracketsExtensionTweetBot
 * http://github.com/ingorichter/BracketsExtensionTweetBot
 *
 * Copyright (c) 2014 Ingo Richter
 * Licensed under the MIT license.
###
# jslint vars: true, plusplus: true, devel: true, node: true, nomen: true, indent: 4, maxerr: 50

'use strict'

Promise           = require 'bluebird'
TwitterPublisher  = require './TwitterPublisher'
RegistryUtils     = require './RegistryUtils'
dotenv            = require 'dotenv-safe'
process           = require 'process'

dotenv.config({path: '/opt/betb/.env' });

NOTIFICATION_TYPE = {
  'UPDATE': 'UPDATE',
  'NEW': 'NEW'
}

dryRun = false

if process.argv.length == 3 && process.argv[2] == 'dryRun'
  dryRun = true

createChangeset = (oldRegistry, newRegistry) ->
  changesets = []

  for own extensionName, extension of newRegistry
    previousExtension = oldRegistry?[extensionName]

    if previousExtension
      previousVersionsCount = previousExtension.versions.length
      type = NOTIFICATION_TYPE.UPDATE if extension.versions.length > previousVersionsCount
      type = undefined if extension.versions.length is previousVersionsCount
    else type = NOTIFICATION_TYPE.NEW

    if type is NOTIFICATION_TYPE.UPDATE or type is NOTIFICATION_TYPE.NEW
      # determine what to provide for homepage if the homepage isn't available
      _homepage = extension.metadata.homepage
      if not _homepage
        _homepage = extension.metadata.repository?.url

      changeRecord = {
        type: type,
        title: extension.metadata.title ? extension.metadata.name,
        version: extension.metadata.version,
        downloadUrl: RegistryUtils.extensionDownloadURL(extension),
        description: extension.metadata.description,
        homepage: _homepage ? ""
      }

      changesets.push changeRecord

  changesets

createTwitterConfig = ->
  twitterConf = {}
  twitterConf.consumer_key = process.env.TWITTER_CONSUMER_KEY
  twitterConf.consumer_secret = process.env.TWITTER_CONSUMER_SECRET
  twitterConf.access_token = process.env.TWITTER_ACCESS_TOKEN
  twitterConf.access_token_secret = process.env.TWITTER_ACCESS_TOKEN_SECRET

  twitterConf

#
# createNotification
#
createNotification = (changeRecord) ->
  "#{changeRecord.title} - #{changeRecord.version}
 (#{changeRecord.type}) #{changeRecord.homepage} #{changeRecord.downloadUrl} @brackets"

#
# dryRunTwitterClient for debugging and dry run testing
#
dryRunTwitterClient = ->
  dryRunTwitterClient = {
    post: (endpoint, tweet) ->
      # TODO(Ingo): replace with logging infrastructure
      # console.log tweet.status
      Promise.resolve(tweet.status)
  }

# This is the main function
rockAndRoll = ->
  new Promise (resolve, reject) ->
    Promise.join(RegistryUtils.loadLocalRegistry(), RegistryUtils.downloadExtensionRegistry(),
      (oldRegistry, newRegistry) ->
        notifications = createChangeset(oldRegistry, newRegistry).map (changeRecord) ->
          createNotification changeRecord

        twitterConf = createTwitterConfig()

        twitterPublisher = new TwitterPublisher twitterConf

        twitterPublisher.setClient dryRunTwitterClient() if dryRun

        twitterPublisher.post notification for notification in notifications

        RegistryUtils.swapRegistryFiles(newRegistry).then ->
          resolve()
      )

# API
exports.createChangeset     = createChangeset
exports.createNotification  = createNotification
exports.createTwitterConfig = createTwitterConfig
exports.rockAndRoll         = rockAndRoll