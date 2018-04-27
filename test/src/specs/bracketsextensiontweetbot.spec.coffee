'use strict'

bracketsextensiontweetbot = rewiresource("bracketsextensiontweetbot")

fs = require "fs"
path = require "path"
Promise = require "bluebird"
zlib = require "zlib"

oldRegistry = JSON.parse('{"de.richter.brackets.jsonlint":{"metadata":{"name":"de.richter.brackets.jsonlint","version":"0.1.1","description":"JSONLint Extension for Brackets","title":"JSONLint Extension for Brackets","scripts":{"test":"mocha unittests.js"},"repository":{"type":"git","url":"https://github.com/ingorichter/de.richter.brackets.jsonlint"},"keywords":["jsonlint","brackets","javascript","linting","codequality","inspection"],"engines":{"brackets":">=0.30.0"},"author":{"name":"Ingo Richter","email":"ingo.richter+github@gmail.com"},"license":"MIT","bugs":{"url":"https://github.com/ingorichter/de.richter.brackets.jsonlint/issues"}},"owner":"github:ingorichter","versions":[{"version":"0.1.0","published":"2013-09-19T01:15:36.391Z","brackets":">=0.30.0"},{"version":"0.1.1","published":"2013-09-19T01:19:12.447Z","brackets":">=0.30.0"}]}}')

newRegistry = JSON.parse('{"de.richter.brackets.jsonlint":{"metadata":{"name":"de.richter.brackets.jsonlint","version":"0.1.1","homepage":"http://ingorichter.blogspot.com/jsonlint","description":"JSONLint Extension for Brackets","title":"JSONLint Extension for Brackets","scripts":{"test":"mocha unittests.js"},"repository":{"type":"git","url":"https://github.com/ingorichter/de.richter.brackets.jsonlint"},"keywords":["jsonlint","brackets","javascript","linting","codequality","inspection"],"engines":{"brackets":">=0.30.0"},"author":{"name":"Ingo Richter","email":"ingo.richter+github@gmail.com"},"license":"MIT","bugs":{"url":"https://github.com/ingorichter/de.richter.brackets.jsonlint/issues"}},"owner":"github:ingorichter","versions":[{"version":"0.1.0","published":"2013-09-19T01:15:36.391Z","brackets":">=0.30.0"},{"version":"0.1.1","published":"2013-09-19T01:19:12.447Z","brackets":">=0.30.0"},{"version":"0.1.1","published":"2013-09-19T01:19:12.447Z","brackets":">=0.30.0"}]}}')

registryWithoutHomepage = JSON.parse('{"de.richter.brackets.jsonlint":{"metadata":{"name":"de.richter.brackets.jsonlint","version":"0.1.1","description":"JSONLint Extension for Brackets","title":"JSONLint Extension for Brackets","scripts":{"test":"mocha unittests.js"},"repository":{"type":"git","url":"https://github.com/ingorichter/de.richter.brackets.jsonlint"},"keywords":["jsonlint","brackets","javascript","linting","codequality","inspection"],"engines":{"brackets":">=0.30.0"},"author":{"name":"Ingo Richter","email":"ingo.richter+github@gmail.com"},"license":"MIT","bugs":{"url":"https://github.com/ingorichter/de.richter.brackets.jsonlint/issues"}},"owner":"github:ingorichter","versions":[{"version":"0.1.0","published":"2013-09-19T01:15:36.391Z","brackets":">=0.30.0"},{"version":"0.1.1","published":"2013-09-19T01:19:12.447Z","brackets":">=0.30.0"},{"version":"0.1.1","published":"2013-09-19T01:19:12.447Z","brackets":">=0.30.0"}]}}')

registryWithoutAnyHomepage = JSON.parse('{"de.richter.brackets.jsonlint":{"metadata":{"name":"de.richter.brackets.jsonlint","version":"0.1.1","description":"JSONLint Extension for Brackets","title":"JSONLint Extension for Brackets","scripts":{"test":"mocha unittests.js"},"repository":{"type":"git"},"keywords":["jsonlint","brackets","javascript","linting","codequality","inspection"],"engines":{"brackets":">=0.30.0"},"author":{"name":"Ingo Richter","email":"ingo.richter+github@gmail.com"},"license":"MIT","bugs":{"url":"https://github.com/ingorichter/de.richter.brackets.jsonlint/issues"}},"owner":"github:ingorichter","versions":[{"version":"0.1.0","published":"2013-09-19T01:15:36.391Z","brackets":">=0.30.0"},{"version":"0.1.1","published":"2013-09-19T01:19:12.447Z","brackets":">=0.30.0"},{"version":"0.1.1","published":"2013-09-19T01:19:12.447Z","brackets":">=0.30.0"}]}}')

registryWithoutTitleButName = JSON.parse('{"de.richter.brackets.jsonlint":{"metadata":{"name":"de.richter.brackets.jsonlint","version":"0.1.1","description":"JSONLint Extension for Brackets"}}}')

describe "Extension Registry Update Notifications", ->
  describe "Detect Registry Changes", ->
    it "should not show any changes", (done) ->
      changesets = bracketsextensiontweetbot.createChangeset {}, {}
      changesets.should.have.length 0
      done()

    it "should generate one change record with type UPDATE", (done) ->
      changesets = bracketsextensiontweetbot.createChangeset oldRegistry, newRegistry
      changesets.should.have.length 1
      changeRecord = changesets[0]

      expect(changeRecord).to.have.property("type", "UPDATE")
      expect(changeRecord).to.have.property("title", "JSONLint Extension for Brackets")
      expect(changeRecord).to.have.property("downloadUrl", "https://s3.amazonaws.com/extend.brackets/de.richter.brackets.jsonlint/de.richter.brackets.jsonlint-0.1.1.zip")
      expect(changeRecord).to.have.property("description", "JSONLint Extension for Brackets")
      expect(changeRecord).to.have.property("version", "0.1.1")
      expect(changeRecord).to.have.property("homepage", "http://ingorichter.blogspot.com/jsonlint")

      done()

    it "should generate one change record with type NEW", (done) ->
      changesets = bracketsextensiontweetbot.createChangeset {}, newRegistry
      changesets.should.have.length 1
      changeRecord = changesets[0]

      expect(changeRecord).to.have.property("type", "NEW")
      expect(changeRecord).to.have.property("title", "JSONLint Extension for Brackets")
      expect(changeRecord).to.have.property("downloadUrl", "https://s3.amazonaws.com/extend.brackets/de.richter.brackets.jsonlint/de.richter.brackets.jsonlint-0.1.1.zip")
      expect(changeRecord).to.have.property("description", "JSONLint Extension for Brackets")
      expect(changeRecord).to.have.property("version", "0.1.1")
      expect(changeRecord).to.have.property("homepage", "http://ingorichter.blogspot.com/jsonlint")

      done()

    it "should generate one change record with homepage set to repository url", (done) ->
      changesets = bracketsextensiontweetbot.createChangeset {}, registryWithoutHomepage
      changesets.should.have.length 1
      changeRecord = changesets[0]

      expect(changeRecord).to.have.property("type", "NEW")
      expect(changeRecord).to.have.property("title", "JSONLint Extension for Brackets")
      expect(changeRecord).to.have.property("downloadUrl", "https://s3.amazonaws.com/extend.brackets/de.richter.brackets.jsonlint/de.richter.brackets.jsonlint-0.1.1.zip")
      expect(changeRecord).to.have.property("description", "JSONLint Extension for Brackets")
      expect(changeRecord).to.have.property("version", "0.1.1")
      expect(changeRecord).to.have.property("homepage", "https://github.com/ingorichter/de.richter.brackets.jsonlint")

      done()

    it "should generate one change record with no homepage url", (done) ->
      changesets = bracketsextensiontweetbot.createChangeset {}, registryWithoutAnyHomepage
      changesets.should.have.length 1
      changeRecord = changesets[0]

      expect(changeRecord).to.have.property("type", "NEW")
      expect(changeRecord).to.have.property("title", "JSONLint Extension for Brackets")
      expect(changeRecord).to.have.property("downloadUrl", "https://s3.amazonaws.com/extend.brackets/de.richter.brackets.jsonlint/de.richter.brackets.jsonlint-0.1.1.zip")
      expect(changeRecord).to.have.property("description", "JSONLint Extension for Brackets")
      expect(changeRecord).to.have.property("version", "0.1.1")
      expect(changeRecord).to.have.property("homepage", "")

      done()

    it "should generate lots of change record", (done) ->
      oldRegistryObject = JSON.parse(zlib.gunzipSync(fs.readFileSync(path.join(path.dirname(module.filename), "../../testdata/extensionRegistry.json.gz"))))

      newRegistryObject = JSON.parse(fs.readFileSync(path.join(path.dirname(module.filename), "../../testdata/extensionRegistryNew.json")))

      changesets = bracketsextensiontweetbot.createChangeset oldRegistryObject, newRegistryObject
      changesets.should.have.length 21
      changeRecord = changesets[0]

      done()

    it "should generate no change record for unchanged extensions", (done) ->
      changesets = bracketsextensiontweetbot.createChangeset oldRegistry, oldRegistry
      changesets.should.have.length 0

      done()

    it "should use name if title is not available in package.json", (done) ->
      changesets = bracketsextensiontweetbot.createChangeset {}, registryWithoutTitleButName
      changesets.should.have.length 1
      changeRecord = changesets[0]

      expect(changeRecord).to.have.property("type", "NEW")
      expect(changeRecord).to.have.property("title", "de.richter.brackets.jsonlint")
      expect(changeRecord).to.have.property("downloadUrl", "https://s3.amazonaws.com/extend.brackets/de.richter.brackets.jsonlint/de.richter.brackets.jsonlint-0.1.1.zip")
      expect(changeRecord).to.have.property("description", "JSONLint Extension for Brackets")
      expect(changeRecord).to.have.property("version", "0.1.1")
      expect(changeRecord).to.have.property("homepage", "")

      done()

    describe "Create twitter Notification", ->
      it "should generate notification for new extension", (done) ->
        changeRecord = {
          type: "NEW",
          title: "test-extension",
          version: "0.1.1",
          downloadUrl: "https://s3.amazonaws.com/extend.brackets/de.richter.brackets.jsonlint/de.richter.brackets.jsonlint-0.1.1.zip",
          description: "JSONLint Extension for Brackets",
          homepage: "https://github.com/ingorichter/de.richter.brackets.jsonlint"
        }

        notification = bracketsextensiontweetbot.createNotification changeRecord

        notification.should.equal "test-extension - 0.1.1 (NEW) https://github.com/ingorichter/de.richter.brackets.jsonlint https://s3.amazonaws.com/extend.brackets/de.richter.brackets.jsonlint/de.richter.brackets.jsonlint-0.1.1.zip @brackets"

        done()

    it "should generate notification for new extension with repo instead of homepage", (done) ->
      changeRecord = {
        type: "NEW",
        title: "test-extension",
        version: "0.1.1",
        downloadUrl: "https://s3.amazonaws.com/extend.brackets/de.richter.brackets.jsonlint/de.richter.brackets.jsonlint-0.1.1.zip",
        description: "JSONLint Extension for Brackets",
        homepage: "https://github.com/ingorichter/de.richter.brackets.jsonlint"
      }

      notification = bracketsextensiontweetbot.createNotification changeRecord

      notification.should.equal "test-extension - 0.1.1 (NEW) https://github.com/ingorichter/de.richter.brackets.jsonlint https://s3.amazonaws.com/extend.brackets/de.richter.brackets.jsonlint/de.richter.brackets.jsonlint-0.1.1.zip @brackets"

      done()

    describe "Rock and Roll", ->
      it "should call all functions before tweeting the updates", (done) ->
        ccrStub = sinon.stub().returns([1])
        srfStub = sinon.stub().returns(Promise.resolve())
        ruSpy = {
          downloadExtensionRegistry: ->
            Promise.resolve()

          loadLocalRegistry: ->
            Promise.resolve()

          swapRegistryFiles: srfStub
        }

        tw = (config) ->
          console.log "TwitterPublisher created"

        tw.prototype = Object.create(Object.prototype)
        tw.prototype.post = (data) ->
          console.log "Debug: #{data}"

        bracketsextensiontweetbot.__set__("RegistryUtils", ruSpy)
        bracketsextensiontweetbot.__set__("createChangeset", ccrStub)
        bracketsextensiontweetbot.__set__("TwitterPublisher", tw)

        bracketsextensiontweetbot.rockAndRoll().then ->
          expect(ruSpy.swapRegistryFiles.calledOnce).to.be.true
          done()
        return
