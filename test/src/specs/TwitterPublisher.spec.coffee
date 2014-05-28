#rewire = require 'rewire'
#tp = rewire '../../../dist/TwitterPublisher'
fs = require 'fs'
path = require 'path'
tp = source 'TwitterPublisher'

describe "TwitterPublisher", ->
  beforeEach ->
    @testData = JSON.parse(fs.readFileSync(path.join(path.dirname(module.filename), "../../testdata/twitter/feeds-1.json")))

  describe "Timeline", ->
    @tc

    beforeEach ->
      @tc = new tp({
        "consumer_key":         "key",
        "consumer_secret":      "secret",
        "access_token":         "token",
        "access_token_secret":  "token_secret"
      })

    it "should return a timeline with 20 tweets", (done) ->
      # setup stub provider
      provider = {get: -> }
      @stub = sinon.stub(provider, 'get')
      @stub.callsArgWith(2, '', @testData)
      @tc.setClient(provider)

      promise = @tc.userTimeLine()
      promise.done (tweets) ->
        assert.lengthOf tweets, 20
        done()

    it "should return a timeline with 30 tweets", (done) ->
      # setup stub provider
      provider = {get: -> }
      @stub = sinon.stub(provider, 'get')
      @stub.callsArgWith(2, '', @testData)
      @tc.setClient(provider)

      promise = @tc.userTimeLine()
      promise.done (tweets) ->
        assert.lengthOf tweets, 20
        done()
