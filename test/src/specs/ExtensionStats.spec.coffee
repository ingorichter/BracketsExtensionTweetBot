rewire = require 'rewire'
es = rewire '../../../dist/ExtensionStats'
#es = rewire '../../../src/ExtensionStats.coffee'
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
  @registry
  beforeEach ->
    es.__set__('TWITTER_CONFIG', path.resolve(__dirname, '../../testdata/twitterconfig.json'))

    @testData = (JSON.parse(fs.readFileSync(path.join(path.dirname(module.filename), "../../testdata/twitter/feeds-#{num}.json"))) for num in [1..5])
    @registry = JSON.parse(fs.readFileSync(path.join(path.dirname(module.filename), "../../testdata/registry.json")))

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

  describe "Registry JSON", ->
    beforeEach ->
      es.__set__ 'RegistryUtils', {
        downloadExtensionRegistry: =>
          Promise.resolve @registry
      }

    it "should download the registry", (done) ->
      p = es.getRegistry()
      p.then (registry) ->
        expect(registry).to.not.be.null
        expect(Object.keys(registry).length).to.equal(349)
        done()
      return

    describe "Create Changeset", ->
      it "should download the registry and create an empty changeset", (done) ->
        json = es.createChangeSetFromRegistry({})
        expect(json).to.not.be.null
        Object.keys(json.NEW).should.have.length 0
        Object.keys(json.UPDATE).should.have.length 0
        done()

      it "should create a changeset with new and updated extensions", (done) ->
        registry = {
          extension1: {
            versions: [{published: "2014-06-23T03:04:59Z"}, {published: "2014-06-23T03:04:59Z"}]
          },
          extension2: {
            versions: [{published: "2014-06-23T03:04:59Z"},
                       {published: "2014-06-23T03:04:59Z"},
                       {published: "2014-06-23T03:04:59Z"}]
          },
          extension3: {
            versions: [{published: "2014-06-23T03:04:59Z"}]
          }
        }

        json = es.createChangeSetFromRegistry(registry)
        Object.keys(json.NEW).should.have.length 1
        Object.keys(json.UPDATE).should.have.length 2
        done()

    describe "Create Markdown for Changeset", ->
      it "should download the registry and create a changeset with new and updated extensions", (done) ->
        registry = {
            "io.brackets.color-palette": {
              metadata: {
                name:"io.brackets.color-palette",
                title:"Brackets Color Palette",
                description:"Pick colors directly from images (*.png, *.jpg, *.jpeg, *.gif, *.ico)",
                homepage:"https://github.com/sprintr/brackets-color-palette",
                version:"1.2.0"
              },
              versions: [{published: "2014-06-23T03:04:59Z"}, {published: "2014-06-23T03:04:59Z"}]
            },
            "recognizer": {
              metadata: {
                name:"recognizer",
                version:"0.0.5",
                description:"Inspect JavaScript variables real-time. This is still experimental, please follow instructions at https://github.com/equiet/recognizer.",
                homepage:"https://github.com/equiet/recognizer",
                main:"main.js"
              },
              versions: [{published: "2014-06-23T03:04:59Z"},
                         {published: "2014-06-23T03:04:59Z"},
                         {published: "2014-06-23T03:04:59Z"}]
            },
            "ficompiler": {
              metadata: {
                name:"ficompiler",
                version:"1.3.1",
                title:"Fi Compiler",
                homepage:"https://github.com/FinalDevStudio/ficompiler",
                description:"Compile LESS and JavaScript (Browserify & Uglify) on save."
              },
              versions: [{published: "2014-06-23T03:04:59Z"}]
            }
        }

        changeSet = es.createChangeSetFromRegistry(registry)
        expect(changeSet).to.not.be.null
        Object.keys(changeSet.UPDATE).should.have.length 2
        Object.keys(changeSet.NEW).should.have.length 1

        markdown = es.transfromRegistryChangeset(changeSet)

        expected = """
    ## 1 new Extensions
    ## 2 updated Extensions
    ## New Extensions
    | Name | Version | Description | Download |
    |------|---------|-------------|----------|
    |[Fi Compiler](https://github.com/FinalDevStudio/ficompiler)|1.3.1|Compile LESS and JavaScript (Browserify & Uglify) on save.|<a href=\"https://s3.amazonaws.com/extend.brackets/ficompiler/ficompiler-1.3.1.zip\"><div class=\"imageHolder\"><img src=\"images/cloud_download.svg\" class=\"image\"/></div></a>|

    ## Updated Extensions
    | Name | Version | Description | Download |
    |------|---------|-------------|----------|
    |[Brackets Color Palette](https://github.com/sprintr/brackets-color-palette)|1.2.0|Pick colors directly from images (*.png, *.jpg, *.jpeg, *.gif, *.ico)|<a href=\"https://s3.amazonaws.com/extend.brackets/io.brackets.color-palette/io.brackets.color-palette-1.2.0.zip\"><div class=\"imageHolder\"><img src=\"images/cloud_download.svg\" class=\"image\"/></div></a>|
    |[recognizer](https://github.com/equiet/recognizer)|0.0.5|Inspect JavaScript variables real-time. This is still experimental, please follow instructions at https://github.com/equiet/recognizer.|<a href=\"https://s3.amazonaws.com/extend.brackets/recognizer/recognizer-0.0.5.zip\"><div class=\"imageHolder\"><img src=\"images/cloud_download.svg\" class=\"image\"/></div></a>|
    """
        expect(expected).to.equal(markdown)
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
## 1 new Extensions
## 2 updated Extensions
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
## 1 updated Extensions
## Updated Extensions
| Name | Version | Description | Download |
|------|---------|-------------|----------|
|[Brackets Color Palette](https://s3.amazonaws.com/extend.brackets/io.brackets.color-palette/io.brackets.color-palette-0.1.2.zip)|0.1.2|N/A|<a href=\"https://s3.amazonaws.com/extend.brackets/io.brackets.color-palette/io.brackets.color-palette-0.1.2.zip\"><div class=\"imageHolder\"><img src=\"images/cloud_download.svg\" class=\"image\"/></div></a>|
"""
      expect(expected).to.equal(markdown)
