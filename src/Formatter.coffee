###
 * Formatter
 * http://github.com/ingorichter/BracketsExtensionTweetBot
 *
 * Copyright (c) 2014 Ingo Richter
 * Licensed under the MIT license.
###

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
      result += "## #{newExtensions.length} new Extensions" if newExtensions.length
      result += "\n" if newExtensions.length
      result += "## #{updatedExtensions.length} updated Extensions" if updatedExtensions.length
      result += "\n" if updatedExtensions.length
      result += "## New Extensions" + "\n" + header + "\n" + newExtensions.join("\n") if newExtensions.length
      result += "\n\n" if newExtensions.length and updatedExtensions.length
      result += "## Updated Extensions" + "\n" + header + "\n" + updatedExtensions.join("\n") if updatedExtensions.length
