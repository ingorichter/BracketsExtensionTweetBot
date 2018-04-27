###
 * BracketsExtensionTweetBot
 * http://github.com/ingorichter/BracketsExtensionTweetBot
 *
 * Copyright (c) 2014 Ingo Richter
 * Licensed under the MIT license.
###
# jslint vars: true, plusplus: true, devel: true, node: true, nomen: true, indent: 4, maxerr: 50

'use strict'
Promise = require 'bluebird'
request = require 'request'
zlib = require 'zlib'
fs = Promise.promisifyAll(require 'fs')
path = require 'path'
dotenv = require 'dotenv-safe'

dotenv.config()

# config
REGISTRY_BASEURL = process.env.REGISTRY_BASEURL
BRACKETS_REGISTRY_JSON = "#{REGISTRY_BASEURL}/registry.json"
REGISTRY_JSON = path.resolve(__dirname, '../extensionRegistry.json.gz')

downloadExtensionRegistry = ->
  new Promise (resolve, reject) ->
    request { uri: BRACKETS_REGISTRY_JSON, json: true, encoding: null }, (err, resp, body) ->
      if err
        reject err
      else
        fs.writeFile './extensionRegistry.json.gz', body, (err) ->
          if err
            reject err
          else
            zlib.gunzip body, (err, buffer) ->
              if err
                reject err
              else
                resolve JSON.parse buffer.toString()

# helper to create a canonical URL to download the extension
extensionDownloadURL = (extension) ->
  "#{REGISTRY_BASEURL}/#{extension.metadata.name}/#{extension.metadata.name}-#{extension.metadata.version}.zip"

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

# API
exports.downloadExtensionRegistry = downloadExtensionRegistry
exports.extensionDownloadURL = extensionDownloadURL
exports.loadLocalRegistry = loadLocalRegistry
exports.swapRegistryFiles = swapRegistryFiles
