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
fs = require 'fs'

REGISTRY_BASEURL = 'https://s3.amazonaws.com/extend.brackets'
BRACKETS_REGISTRY_JSON = "#{REGISTRY_BASEURL}/registry.json"

downloadExtensionRegistry = ->
  new Promise (resolve, reject) ->
    request {uri: BRACKETS_REGISTRY_JSON, json: true, encoding: null}, (err, resp, body) ->
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

# API
exports.downloadExtensionRegistry = downloadExtensionRegistry
