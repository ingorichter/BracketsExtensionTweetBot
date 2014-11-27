###
 * Formatter
 * http://github.com/ingorichter/BracketsExtensionTweetBot
 *
 * Copyright (c) 2014 Ingo Richter
 * Licensed under the MIT license.
###
# jslint vars: true, plusplus: true, devel: true, node: true, nomen: true, indent: 4, maxerr: 50

'use strict'

module.exports =
  class Formatter
    header = """
  | Name | Version | Description | Download |
  |------|---------|-------------|----------|
  """

    formatUrl: (url) ->
      "<a href=\"#{url}\"><div class=\"imageHolder\"><img src=\"images/cloud_download.svg\" class=\"image\"/></div></a>"

    formatResult: (newExtensions, updatedExtensions) ->
      # format result
      result = ""
      result = "## New Extensions" + "\n" + header + "\n" + newExtensions.join("\n") if newExtensions.length
      result += "\n" if newExtensions.length and updatedExtensions.length
      result += "## Updated Extensions" + "\n" + header + "\n" + updatedExtensions.join("\n") if updatedExtensions.length
