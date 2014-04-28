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
zlib = require 'zlib'
https = require 'https'
promise = require 'bluebird'
fs = promise.promisifyAll(require 'fs')
request = require 'request'
TwitterPublisher = require './TwitterPublisher'

NOTIFICATION_TYPE = {
  'UPDATE': 'UPDATE',
  'NEW': 'NEW'
}

REGISTRY_BASEURL = 'https://s3.amazonaws.com/extend.brackets'
BRACKETS_REGISTRY_JSON = "#{REGISTRY_BASEURL}/registry.json"
TWITTER_CONFIG = path.resolve(__dirname, '../twitterconfig.json')
REGISTRY_JSON = path.resolve(__dirname, '../extensionRegistry.json')

loadLocalRegistry = ->
  deferred = promise.defer()

  p = readFile(REGISTRY_JSON)

  p.then (data) -> deferred.resolve JSON.parse(data)

  p.catch((err) ->
    ## file doesn't exist
    if (err.cause.errno is 34)
      deferred.resolve {}
    else
      deferred.reject err
  )

  return deferred.promise

downloadExtensionRegistry = ->
  deferred = promise.defer()

  request {uri: BRACKETS_REGISTRY_JSON, json: true, encoding: null}, (err, resp, body) ->
    if err
      deferred.reject err
      return
    else
      zlib.gunzip body, (err, buffer) ->
        if err
          console.error err
          deferred.reject err
          return
        else
          deferred.resolve(JSON.parse(buffer.toString()))
          return
      return

  deferred.promise

downloadUrl = (extension) ->
  "#{REGISTRY_BASEURL}/#{extension.metadata.name}/#{extension.metadata.name}-#{extension.metadata.version}.zip"

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
        downloadUrl: downloadUrl(extension),
        description: extension.metadata.description,
        homepage: _homepage ? ""
      }

      changesets.push changeRecord

  changesets

#
# createNotification
#
createNotification = (changeRecord) ->
  "#{changeRecord.title} - #{changeRecord.version}
 (#{changeRecord.type}) #{changeRecord.homepage} #{changeRecord.downloadUrl} @brackets"

swapRegistryFiles = (newContent) ->
  extRegBackupDir = path.resolve(__dirname, "../.oldExtensionRegistries")
  fs.mkdirSync(extRegBackupDir) if not fs.existsSync(extRegBackupDir)

  d = new Date()

  fs.createReadStream(REGISTRY_JSON).pipe(
    fs.createWriteStream(path.join(extRegBackupDir, "#{d.getTime()}-extensionRegistry.json")))

  fs.writeFileSync(REGISTRY_JSON, JSON.stringify(newContent))
  return

# This is the main function
rockAndRoll = ->
  loadLocalRegistry().then (oldRegistry) ->
    downloadExtensionRegistry().then (newRegistry) ->
      notifications = createChangeset(oldRegistry, newRegistry).map (changeRecord) ->
        createNotification changeRecord

      # read twitter config file
      twitterConf = JSON.parse(fs.readFileSync(TWITTER_CONFIG))

      twitterPublisher = new TwitterPublisher twitterConf
      twitterPublisher.post notification for notification in notifications

      swapRegistryFiles(newRegistry)

# API
exports.createChangeset = createChangeset
exports.createNotification = createNotification
exports.rockAndRoll = rockAndRoll