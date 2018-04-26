###
 * BracketsExtensionTweetBot
 * http://github.com/ingorichter/BracketsExtensionTweetBot
 *
 * Copyright (c) 2014 Ingo Richter
 * Licensed under the MIT license.
###
# jslint vars: true, plusplus: true, devel: true, node: true, nomen: true, indent: 4, maxerr: 50

'use strict'

path              = require 'path'
https             = require 'https'
Promise           = require 'bluebird'
fs                = Promise.promisifyAll(require 'fs')
TwitterPublisher  = require './TwitterPublisher'
RegistryUtils     = require './RegistryUtils'
_                 = require 'lodash'
zlib              = require 'zlib'
dotenv            = require 'dotenv-safe'

dotenv.config()

NOTIFICATION_TYPE = {
  'UPDATE': 'UPDATE',
  'NEW': 'NEW'
}

# config
REGISTRY_BASEURL = process.env.REGISTRY_BASEURL
REGISTRY_JSON = path.resolve(__dirname, '../extensionRegistry.json.gz')

loadLocalRegistry = (registry) ->
  new Promise (resolve, reject) ->
    registry = registry || REGISTRY_JSON
    p = fs.readFileAsync(registry).then (data) ->
      zlib.gunzip data, (err, buffer) ->
        if err
          reject err
        else
          resolve JSON.parse buffer.toString()

    p.catch (err) ->
      ## file doesn't exist
      if (err.cause.code is "ENOENT")
        resolve {}
      else
        reject err

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
  new Promise (resolve, reject) ->
    extRegBackupDir = path.resolve(__dirname, "../.oldExtensionRegistries")
    fs.mkdirSync(extRegBackupDir) if not fs.existsSync(extRegBackupDir)

    d = new Date()

    gzip = zlib.createGzip()

    fs.createReadStream(REGISTRY_JSON).pipe(gzip).pipe(
      fs.createWriteStream(path.join(extRegBackupDir, "#{d.getTime()}-extensionRegistry.json.gz")))

    zlib.gzip JSON.stringify(newContent), (err, buffer) ->
      if (err)
        reject(err)
      else
        fs.writeFile(REGISTRY_JSON, buffer, (err) ->
          if (err)
            reject(err)
          else
            resolve()
        )

# This is the main function
rockAndRoll = ->
  new Promise (resolve, reject) ->
    Promise.join(loadLocalRegistry(), RegistryUtils.downloadExtensionRegistry(), (oldRegistry, newRegistry) ->
      notifications = createChangeset(oldRegistry, newRegistry).map (changeRecord) ->
        createNotification changeRecord

      twitterConf = {}
      twitterConf.consumer_key = process.env.TWITTER_CONSUMER_KEY
      twitterConf.consumer_secret = process.env.TWITTER_CONSUMER_SECRET
      twitterConf.access_token = process.env.TWITTER_ACCESS_TOKEN
      twitterConf.access_token_secret = process.env.TWITTER_ACCESS_TOKEN_SECRET

      twitterPublisher = new TwitterPublisher twitterConf
      twitterPublisher.post notification for notification in notifications

      swapRegistryFiles(newRegistry).then ->
        resolve()
    )

# API
exports.createChangeset     = createChangeset
exports.createNotification  = createNotification
exports.rockAndRoll         = rockAndRoll
exports.loadLocalRegistry   = loadLocalRegistry
