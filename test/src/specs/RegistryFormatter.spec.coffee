'use strict'

RegistryFormatter = source 'RegistryFormatter'
path = require 'path'

describe "Registry Formatter", ->
  it "should create the canonical download URL for a given extension", ->
    testExtension = {}
    testExtension.metadata = {}
    testExtension.metadata.name = "TestExtension"
    testExtension.metadata.homepage = "http://www.testextension.com"
    testExtension.metadata.description = "a fine test extension"
    testExtension.metadata.version = "1.0"
    
    formatter = new RegistryFormatter()
    result = formatter.formatExtensionEntry(testExtension)

    expect(result).to.equal('|[TestExtension](http://www.testextension.com)|1.0|a fine test extension|<a href="https://s3.amazonaws.com/extend.brackets/TestExtension/TestExtension-1.0.zip"><div class="imageHolder"><img src="images/cloud_download.svg" class="image"/></div></a>|')
