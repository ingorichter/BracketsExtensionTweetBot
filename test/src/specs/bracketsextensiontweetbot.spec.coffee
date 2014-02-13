'use strict';

bracketsextensiontweetbot = source("bracketsextensiontweetbot")

fs = require "fs"
path = require "path"

oldRegistry = JSON.parse('{"de.richter.brackets.jsonlint":{"metadata":{"name":"de.richter.brackets.jsonlint","version":"0.1.1","description":"JSONLint Extension for Brackets","title":"JSONLint Extension for Brackets","scripts":{"test":"mocha unittests.js"},"repository":{"type":"git","url":"https://github.com/ingorichter/de.richter.brackets.jsonlint"},"keywords":["jsonlint","brackets","javascript","linting","codequality","inspection"],"engines":{"brackets":">=0.30.0"},"author":{"name":"Ingo Richter","email":"ingo.richter+github@gmail.com"},"license":"MIT","bugs":{"url":"https://github.com/ingorichter/de.richter.brackets.jsonlint/issues"}},"owner":"github:ingorichter","versions":[{"version":"0.1.0","published":"2013-09-19T01:15:36.391Z","brackets":">=0.30.0"},{"version":"0.1.1","published":"2013-09-19T01:19:12.447Z","brackets":">=0.30.0"}]}}')

newRegistry = JSON.parse('{"de.richter.brackets.jsonlint":{"metadata":{"name":"de.richter.brackets.jsonlint","version":"0.1.1","description":"JSONLint Extension for Brackets","title":"JSONLint Extension for Brackets","scripts":{"test":"mocha unittests.js"},"repository":{"type":"git","url":"https://github.com/ingorichter/de.richter.brackets.jsonlint"},"keywords":["jsonlint","brackets","javascript","linting","codequality","inspection"],"engines":{"brackets":">=0.30.0"},"author":{"name":"Ingo Richter","email":"ingo.richter+github@gmail.com"},"license":"MIT","bugs":{"url":"https://github.com/ingorichter/de.richter.brackets.jsonlint/issues"}},"owner":"github:ingorichter","versions":[{"version":"0.1.0","published":"2013-09-19T01:15:36.391Z","brackets":">=0.30.0"},{"version":"0.1.1","published":"2013-09-19T01:19:12.447Z","brackets":">=0.30.0"},{"version":"0.1.1","published":"2013-09-19T01:19:12.447Z","brackets":">=0.30.0"}]}}')

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

            done()
    
        xit "should generate lots of change record", (done) ->
            oldRegistry = JSON.parse(fs.readFileSync(path.join(path.dirname(module.filename), "../../testdata/extensionRegistry.json")))
            newRegistry = JSON.parse(fs.readFileSync(path.join(path.dirname(module.filename), "../../testdata/extensionRegistryNew.json")))
            
            changesets = bracketsextensiontweetbot.createChangeset oldRegistry, newRegistry
            console.log changesets
            changesets.should.have.length 21
            changeRecord = changesets[0]

            done()
    
        it "should generate no change record for unchanged extensions", (done) ->
            changesets = bracketsextensiontweetbot.createChangeset oldRegistry, oldRegistry
            changesets.should.have.length 0

            done()
    
    describe "Create twitter Notification", ->
        it "should generate notification for new extension", (done) ->
            changeRecord = {
                type: "NEW",
                title: "test-extension",
                version: "0.1.1",
                downloadUrl: "https://s3.amazonaws.com/extend.brackets/de.richter.brackets.jsonlint/de.richter.brackets.jsonlint-0.1.1.zip",
                description: "JSONLint Extension for Brackets"
            }

            notification = bracketsextensiontweetbot.createNotification changeRecord
    
            notification.should.equal "test-extension - 0.1.1 (NEW) https://s3.amazonaws.com/extend.brackets/de.richter.brackets.jsonlint/de.richter.brackets.jsonlint-0.1.1.zip @brackets"
        
            done()