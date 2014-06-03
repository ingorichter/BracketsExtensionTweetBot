rewire = require 'rewire'
#es = rewire '../../../dist/ExtensionStats'
es = rewire '../../../src/ExtensionStats.coffee'
fs = require 'fs'
path = require 'path'
Promise = require 'bluebird'

class TW
  @tweets
  @callCount

  constructor: (@config) ->
    @callCount = -1

  userTimeLine: (max) =>
    @callCount++
    Promise.resolve(@tweets[@callCount])

describe "ExtensionStats", ->
  beforeEach ->
    es.__set__('TWITTER_CONFIG', path.resolve(__dirname, '../../testdata/twitterconfig.json'))

    @testData = (JSON.parse(fs.readFileSync(path.join(path.dirname(module.filename), "../../testdata/twitter/feeds-#{num}.json"))) for num in [1..5])

  describe "Fetch Tweets for various timeframes", ->
    beforeEach ->
      # configure the expected result
      TW.prototype.tweets = @testData
      es.__set__("TwitterPublisher", TW)

    it "should return a timeline with 50 tweets for the last 7 days (default)", (done) ->
      p = es.getTweets(new Date(Date.UTC(2014, 4, 4, 21, 0)))
      p.done (tweets) ->
        expect(tweets.length).to.equal(50)
        done()

    it "should not return any tweets", (done) ->
      p = es.getTweets(new Date(Date.UTC(2014, 7, 4, 18, 0)))
      p.done (tweets) ->
        expect(tweets.length).to.equal(0)
        done()

    it "should return a timeline with 34 tweets for the last 5 days", (done) ->
      # the last tweet in the test data is of 2014/5/4
      # month is 0 based => 5-1 = 4
      # 5/4/2014 6:00 pm
      p = es.getTweets(new Date(Date.UTC(2014, 4, 4, 23, 0)), 5)
      p.done (tweets) ->
        expect(tweets.length).to.equal(34)
        done()

  describe "Changeset", (done) ->
    it "should create an empty changeset", ->
      cs = es.createChangeSet []
      expect(cs['NEW'].length).to.equal(0)
      expect(cs['UPDATE'].length).to.equal(0)

    it "should create a changeset with 32 updated and 5 new extensions", ->
      dataSet = @testData[0].concat(@testData[1])
      cs = es.createChangeSet dataSet
      expect(cs['NEW'].length).to.equal(5)
      expect(cs['UPDATE'].length).to.equal(32)

  describe "Create markdown from Changeset", ->
    it "should create a formatted representation of the changeset", ->
      # create minimal test data
      testTweets = [
        {
          "text": "Brackets Color Palette - 0.1.2 (UPDATE) https://t.co/Va1lhnzpJx https://t.co/cYtlT3La59 @brackets",
          "entities": {
            "urls": [
              {
                "url": "https://t.co/Va1lhnzpJx",
                "expanded_url": "https://github.com/sprintr/brackets-color-palette"
              },
              {
                "url": "https://t.co/cYtlT3La59",
                "expanded_url": "https://s3.amazonaws.com/extend.brackets/io.brackets.color-palette/io.brackets.color-palette-0.1.2.zip"
              }
            ]
          }
        },
        {
          "text": "Brackets Color Palette - 0.1.1 (UPDATE) https://t.co/Va1lhnzpJx https://t.co/cYtlT3La59 @brackets",
          "entities": {
            "urls": [
              {
                "url": "https://t.co/Va1lhnzpJx",
                "expanded_url": "https://github.com/sprintr/brackets-color-palette"
              },
              {
                "url": "https://t.co/cYtlT3La59",
                "expanded_url": "https://s3.amazonaws.com/extend.brackets/io.brackets.color-palette/io.brackets.color-palette-0.1.1.zip"
              }
            ]
          }
        },
        {
          "text": "recognizer - 0.0.5 (UPDATE) https://t.co/drI72cnCrg https://t.co/Hw9pFXk19H @brackets",
          "entities": {
            "urls": [
              {
                "url": "https://t.co/drI72cnCrg",
                "expanded_url": "https://github.com/equiet/recognizer",
              },
              {
                "url": "https://t.co/ZWlxRFc4o9",
                "expanded_url": "https://s3.amazonaws.com/extend.brackets/recognizer/recognizer-0.0.5.zip",
              }
            ]
          }
        },
        {
          "text": "Fi Compiler - 1.3.1 (NEW) https://t.co/rfuH33MJ3i https://t.co/fUeCdQMg4K @brackets",
          "entities": {
            "urls": [
              {
                "url": "https://t.co/rfuH33MJ3i",
                "expanded_url": "https://github.com/FinalDevStudio/ficompiler",
              },
              {
                "url": "https://t.co/fUeCdQMg4K",
                "expanded_url": "https://s3.amazonaws.com/extend.brackets/ficompiler/ficompiler-1.3.1.zip",
              }
            ]
          }
        },
        {
          "text": "Brackets Color Palette - 0.1.0 (NEW) https://t.co/Va1lhnzpJx https://t.co/6RJR7I6WOp @brackets"
          "entities": {
            "urls": [
              {
                "url": "https://t.co/Va1lhnzpJx",
                "expanded_url": "https://github.com/sprintr/brackets-color-palette",
              },
              {
                "url": "https://t.co/cYtlT3La59",
                "expanded_url": "https://s3.amazonaws.com/extend.brackets/io.brackets.color-palette/io.brackets.color-palette-0.1.1.zip"
              }
            ]
          }
        }
      ]

      changeSet = es.createChangeSet(testTweets)
      markdown = es.transformChangeset(changeSet)

      expected = """
## New Extensions
| Name | Version | Description | Download |
|------|---------|-------------|----------|
|[Fi Compiler](https://github.com/FinalDevStudio/ficompiler)|1.3.1|N/A|<a href=\"https://s3.amazonaws.com/extend.brackets/ficompiler/ficompiler-1.3.1.zip\"><div class=\"imageHolder\"><img src=\"images/cloud_download.svg\" class=\"image\"/></div></a>|
## Updated Extensions
| Name | Version | Description | Download |
|------|---------|-------------|----------|
|[Brackets Color Palette](https://github.com/sprintr/brackets-color-palette)|0.1.2|N/A|<a href=\"https://s3.amazonaws.com/extend.brackets/io.brackets.color-palette/io.brackets.color-palette-0.1.2.zip\"><div class=\"imageHolder\"><img src=\"images/cloud_download.svg\" class=\"image\"/></div></a>|
|[recognizer](https://github.com/equiet/recognizer)|0.0.5|N/A|<a href=\"https://s3.amazonaws.com/extend.brackets/recognizer/recognizer-0.0.5.zip\"><div class=\"imageHolder\"><img src=\"images/cloud_download.svg\" class=\"image\"/></div></a>|
"""
      expect(expected).to.equal(markdown)

    it "should create a formatted representation of the changeset if homepage link is missing", ->
      # create minimal test data
      testTweets = [
        {
          "text": "Brackets Color Palette - 0.1.2 (UPDATE)  https://t.co/cYtlT3La59 @brackets",
          "entities": {
            "urls": [
              {
                "url": "https://t.co/cYtlT3La59",
                "expanded_url": "https://s3.amazonaws.com/extend.brackets/io.brackets.color-palette/io.brackets.color-palette-0.1.2.zip"
              }
            ]
          }
        }
      ]

      changeSet = es.createChangeSet(testTweets)
      markdown = es.transformChangeset(changeSet)

      expected = """
## Updated Extensions
| Name | Version | Description | Download |
|------|---------|-------------|----------|
|[Brackets Color Palette](https://s3.amazonaws.com/extend.brackets/io.brackets.color-palette/io.brackets.color-palette-0.1.2.zip)|0.1.2|N/A|<a href=\"https://s3.amazonaws.com/extend.brackets/io.brackets.color-palette/io.brackets.color-palette-0.1.2.zip\"><div class=\"imageHolder\"><img src=\"images/cloud_download.svg\" class=\"image\"/></div></a>|
"""
      expect(expected).to.equal(markdown)
