'use strict'

registryUtils = source 'RegistryUtils'
path = require 'path'

describe "RegistryUtils", ->
  it "should create the canonical download URL for a given extension", ->
    testExtension = {}
    testExtension.metadata = {}
    testExtension.metadata.name = "TestExtension"
    testExtension.metadata.version = "1.0"
    
    result = registryUtils.extensionDownloadURL testExtension
    expect(result).to.equal("https://s3.amazonaws.com/extend.brackets/TestExtension/TestExtension-1.0.zip")

  describe "Local Registry", ->
    it "should return an empty object if no local registry is available", (done) ->
      promise = registryUtils.loadLocalRegistry "notavailable.json"

      promise.then (json) ->
        expect(json).to.be.empty

      done()

    it "should return the extension registry json object", (done) ->
      promise = registryUtils.loadLocalRegistry path.join(path.dirname(module.filename), "../../testdata/extensionRegistry.json.gz")

      promise.then (json) ->
        Object.keys(json).length.should.equal 214

      done()

