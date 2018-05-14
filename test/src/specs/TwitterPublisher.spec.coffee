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
      promise.then (tweets) ->
        assert.lengthOf tweets, 20
        done()
      return

    it "should return a timeline with 30 tweets", (done) ->
      # setup stub provider
      provider = {get: -> }
      @stub = sinon.stub(provider, 'get')
      @stub.callsArgWith(2, '', @testData)
      @tc.setClient(provider)

      promise = @tc.userTimeLine()
      promise.then (tweets) ->
        assert.lengthOf tweets, 20
        done()
      return

  describe "Post", ->
    @tc

    beforeEach ->
      @tc = new tp({
        "consumer_key":         "key",
        "consumer_secret":      "secret",
        "access_token":         "token",
        "access_token_secret":  "token_secret"
      })

    it "should post successfully", (done) ->
      expectedResult = {
        text: "This is a test",
        id_str: 123,
        created_at: 0
      }

        # setup stub provider
      provider = {post: -> }
      @stub = sinon.stub(provider, 'post')
      @stub.callsArgWith(2, '', expectedResult)
      @tc.setClient(provider)

      @tc.post("This is a test").then (result) ->
        expect(result).to.equal(expectedResult)

        done()
      return

    it "should post and handle the error", (done) ->
      expectedResult = {
        text: "This is a test",
        id_str: 123,
        created_at: 0
      }

        # setup stub provider
      provider = {post: -> }
      @stub = sinon.stub(provider, 'post')
      @stub.callsArgWith(2, "Can't post", undefined)
      @tc.setClient(provider)

      @tc.post("This is a test").catch (result) ->
        expect(result).to.equal("Can't post")

        done()
      return
