###
 * RegistryFormatter
 * http://github.com/ingorichter/BracketsExtensionTweetBot
 *
 * Copyright (c) 2014 Ingo Richter
 * Licensed under the MIT license.
###
# jslint vars: true, plusplus: true, devel: true, node: true, nomen: true, indent: 4, maxerr: 50

'use strict'

Formatter = require './Formatter'
registryUtils = source 'RegistryUtils'

module.exports =
  class RegistryFormatter extends Formatter
    formatExtensionEntry: (extensionEntry) ->
      extensionMetadata = extensionEntry.metadata
      downloadURL = registryUtils.extensionDownloadURL extensionEntry

      "|[#{extensionMetadata.title ?= extensionMetadata.name}](#{extensionMetadata.homepage})|#{extensionMetadata.version}|#{extensionMetadata.description}|#{this.formatUrl(downloadURL)}|"

    transform: (changeSet) ->
      newExtensions = (@formatExtensionEntry extension for extension in changeSet["NEW"])
      updatedExtensions = (@formatExtensionEntry extension for extension in changeSet["UPDATE"])

      @formatResult newExtensions, updatedExtensions
