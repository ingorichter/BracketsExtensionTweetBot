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
axios = require 'axios'
zlib = require 'zlib'
fs = Promise.promisifyAll(require 'fs')
path = require 'path'
dotenv = require 'dotenv-safe'

dotenv.config()

# config
REGISTRY_BASEURL = "https://s3.amazonaws.com/extend.brackets"
BRACKETS_REGISTRY_JSON_URL = "#{REGISTRY_BASEURL}/registry.json"

# local
REGISTRY_SNAPSHOT_LOCATION_DIR = process.env.REGISTRY_SNAPSHOT_LOCATION_DIR
REGISTRY_SNAPSHOT_FILE_LATEST = path.resolve(REGISTRY_SNAPSHOT_LOCATION_DIR, "extensionRegistry.json.gz.new")
REGISTRY_SNAPSHOT_FILE_PREVIOUS = path.resolve(REGISTRY_SNAPSHOT_LOCATION_DIR, "extensionRegistry.json.gz.previous")

downloadExtensionRegistry = ->
  new Promise (resolve, reject) ->
    # response defaults to json and the json is automatically ungzipped
    req = axios.get(BRACKETS_REGISTRY_JSON_URL).then (response) ->
      gzip = zlib.createGzip()

      zlib.gzip JSON.stringify(response.data), (err, buffer) ->
        if err
          reject err
        else
          fs.writeFile(REGISTRY_SNAPSHOT_FILE_LATEST, buffer, (err) ->
            if err
              reject err
            else
              resolve response.data
          )

    req.catch (error) ->
      reject error

# helper to create a canonical URL to download the extension
extensionDownloadURL = (extension) ->
  "#{REGISTRY_BASEURL}/#{extension.metadata.name}/#{extension.metadata.name}-#{extension.metadata.version}.zip"

loadLocalRegistry = (registry) ->
  new Promise (resolve, reject) ->
    registry = registry || REGISTRY_SNAPSHOT_FILE_PREVIOUS
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
  # TODO(Ingo): the directory check needs to be more central
    fs.mkdirSync(REGISTRY_SNAPSHOT_LOCATION_DIR) if not fs.existsSync(REGISTRY_SNAPSHOT_LOCATION_DIR)

    # create timestamp for archived registry
    d = new Date()
    archiveRegistryName = "#{d.getTime()}-extensionRegistry.json.gz"

    # 1. move extensionRegistry.json.gz.previous to ${archiveRegistryName}
    if fs.existsSync(REGISTRY_SNAPSHOT_FILE_PREVIOUS)
      fs.renameAsync(REGISTRY_SNAPSHOT_FILE_PREVIOUS, path.join(REGISTRY_SNAPSHOT_LOCATION_DIR, archiveRegistryName)).then ->
        # 2. move extensionRegistry.json.gz.new to extensionRegistry.json.gz.previous
        if fs.existsSync(REGISTRY_SNAPSHOT_FILE_LATEST)
          fs.renameAsync(REGISTRY_SNAPSHOT_FILE_LATEST, REGISTRY_SNAPSHOT_FILE_PREVIOUS).then ->
            resolve()
        resolve()
    else
        if fs.existsSync(REGISTRY_SNAPSHOT_FILE_LATEST)
          fs.renameAsync(REGISTRY_SNAPSHOT_FILE_LATEST, REGISTRY_SNAPSHOT_FILE_PREVIOUS).then ->
            resolve()
        resolve()

# API
exports.downloadExtensionRegistry = downloadExtensionRegistry
exports.extensionDownloadURL = extensionDownloadURL
exports.loadLocalRegistry = loadLocalRegistry
exports.swapRegistryFiles = swapRegistryFiles
