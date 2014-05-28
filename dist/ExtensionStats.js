
/*
 * BracketsExtensionTweetBot
 * http://github.com/ingorichter/BracketsExtensionTweetBot
 *
 * Copyright (c) 2014 Ingo Richter
 * Licensed under the MIT license.
 */
'use strict';
var DEFAULT_NUMBER_OF_DAYS, NEW_KEY, Promise, TWITTER_CONFIG, TwitterPublisher, UPDATE_KEY, createChangeSet, extractChangesFromTweets, fs, getTweets, getTweetsFromRange, path, removeDuplicatesFromChangeset, search, semver, timeline, transformChangeset, tweetRE, twitterPublisher, _;

path = require('path');

semver = require('semver');

fs = require('fs');

Promise = require('bluebird');

_ = require('lodash');

TwitterPublisher = require('./TwitterPublisher');

TWITTER_CONFIG = path.resolve(__dirname, '../twitterconfig.json');

twitterPublisher = void 0;

DEFAULT_NUMBER_OF_DAYS = 7;

UPDATE_KEY = "UPDATE";

NEW_KEY = "NEW";

tweetRE = /^(.*)\s+-\s+(.+)\s+\(.+\)/;

createChangeSet = function(tweets) {
  var newExtensions, tweet, updatedExtensions;
  newExtensions = (function() {
    var _i, _len, _results;
    _results = [];
    for (_i = 0, _len = tweets.length; _i < _len; _i++) {
      tweet = tweets[_i];
      if (tweet.text.indexOf("(NEW)") > -1) {
        _results.push(tweet);
      }
    }
    return _results;
  })();
  updatedExtensions = (function() {
    var _i, _len, _results;
    _results = [];
    for (_i = 0, _len = tweets.length; _i < _len; _i++) {
      tweet = tweets[_i];
      if (tweet.text.indexOf("(UPDATE)") > -1) {
        _results.push(tweet);
      }
    }
    return _results;
  })();
  return {
    "NEW": newExtensions,
    "UPDATE": updatedExtensions
  };
};

timeline = function(max_id, count) {
  var deferred, promise;
  deferred = Promise.defer();
  promise = twitterPublisher.userTimeLine(max_id, count);
  promise.then(function(data) {
    return deferred.resolve(data);
  });
  promise["catch"](function(err) {
    return deferred.reject(err);
  });
  return deferred.promise;
};

getTweetsFromRange = function(endDate, numberOfDays) {
  var allTweets, deferred, lastTweetDate, startDate, _tweets;
  deferred = Promise.defer();
  if (!endDate) {
    endDate = new Date(Date.now());
  }
  endDate = endDate.getTime();
  numberOfDays = numberOfDays || DEFAULT_NUMBER_OF_DAYS;
  startDate = endDate - (numberOfDays * 24 * 60 * 60 * 1000);
  lastTweetDate = endDate;
  allTweets = [];
  _tweets = function(max_id, count) {
    var promise;
    promise = timeline(max_id, count);
    return promise.then(function(tweets) {
      var tweet, _i, _j, _len, _len1;
      lastTweetDate = new Date(tweets[tweets.length - 1].created_at).getTime();
      if (lastTweetDate > startDate) {
        for (_i = 0, _len = tweets.length; _i < _len; _i++) {
          tweet = tweets[_i];
          allTweets.push(tweet);
        }
        return _tweets(tweets[tweets.length - 1].id, count);
      } else {
        for (_j = 0, _len1 = tweets.length; _j < _len1; _j++) {
          tweet = tweets[_j];
          if (new Date(tweet.created_at).getTime() > startDate) {
            allTweets.push(tweet);
          }
        }
        return deferred.resolve(allTweets);
      }
    });
  };
  _tweets();
  return deferred.promise;
};

getTweets = function(from, to) {
  var deferred, twitterConf;
  twitterConf = JSON.parse(fs.readFileSync(TWITTER_CONFIG));
  twitterPublisher = new TwitterPublisher(twitterConf);
  deferred = Promise.defer();
  getTweetsFromRange(from, to).then(function(tweets) {
    return deferred.resolve(tweets);
  });
  return deferred.promise;
};

extractChangesFromTweets = function(from, to) {
  var deferred;
  deferred = Promise.defer();
  getTweets(from, to).then(function(tweets) {
    var cs;
    cs = createChangeSet(tweets);
    return deferred.resolve(cs);
  });
  return deferred.promise;
};

search = function(query, untilDate) {
  var promise, twitterConf;
  twitterConf = JSON.parse(fs.readFileSync(TWITTER_CONFIG));
  twitterPublisher = new TwitterPublisher(twitterConf);
  promise = twitterPublisher.search(query, untilDate);
  promise.then(function(data) {
    return fs.writeFileSync(path.resolve(__dirname, '../tweets.json'), JSON.stringify(data));
  });
  return promise["catch"](function(err) {
    return console.log(err);
  });
};

removeDuplicatesFromChangeset = function(changeSet) {
  var index, makeObject, newSet, tweet, updatedSet, _i, _len, _removeDuplicates;
  makeObject = function(tweet) {
    var match;
    match = tweet.text.match(tweetRE);
    return {
      name: match[1],
      version: match[2],
      tweet: tweet
    };
  };
  _removeDuplicates = function(changeSet) {
    var index, obj, resultSet, tweet, _i, _len;
    resultSet = [];
    for (_i = 0, _len = changeSet.length; _i < _len; _i++) {
      tweet = changeSet[_i];
      obj = makeObject(tweet);
      index = _.findIndex(resultSet, {
        name: obj.name
      });
      if (index === -1) {
        resultSet.push(obj);
      }
      if (index > -1 && semver.gt(obj.version, resultSet[index].version)) {
        resultSet[index] = obj;
      }
    }
    return resultSet;
  };
  updatedSet = _removeDuplicates(changeSet["UPDATE"]);
  newSet = _removeDuplicates(changeSet["NEW"]);
  for (_i = 0, _len = updatedSet.length; _i < _len; _i++) {
    tweet = updatedSet[_i];
    index = _.findIndex(newSet, {
      name: tweet.name
    });
    if (index > -1) {
      newSet[index] = false;
    }
  }
  return {
    "NEW": _.map(_.compact(newSet), function(obj) {
      return obj.tweet;
    }),
    "UPDATE": _.map(updatedSet, function(obj) {
      return obj.tweet;
    })
  };
};

transformChangeset = function(changeSet) {
  var cleanedChangeSet, formatTweet, header, newTweets, result, tweet, updatedTweets;
  header = "| Name | Version | Description | Homepage | Download |\n|------|---------|-------------|----------|----------|";
  formatTweet = function(tweet) {
    var downloadURL, homePageURL, match, _ref, _ref1;
    match = tweet.text.match(tweetRE);
    homePageURL = (_ref = tweet.entities.urls) != null ? _ref[0].expanded_url : void 0;
    downloadURL = (_ref1 = tweet.entities.urls) != null ? _ref1[1].expanded_url : void 0;
    return "|" + match[1] + "|" + match[2] + "|N/A|" + homePageURL + "|" + downloadURL + "|";
  };
  cleanedChangeSet = removeDuplicatesFromChangeset(changeSet);
  newTweets = (function() {
    var _i, _len, _ref, _results;
    _ref = cleanedChangeSet["NEW"];
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      tweet = _ref[_i];
      _results.push(formatTweet(tweet));
    }
    return _results;
  })();
  updatedTweets = (function() {
    var _i, _len, _ref, _results;
    _ref = cleanedChangeSet["UPDATE"];
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      tweet = _ref[_i];
      _results.push(formatTweet(tweet));
    }
    return _results;
  })();
  if (newTweets.length) {
    result = "# New Extensions" + "\n" + header + "\n" + newTweets.join("\n");
  }
  if (updatedTweets.length) {
    result += "\n" + "# Updated Extensions" + "\n" + header + "\n" + updatedTweets.join("\n");
  }
  return result;
};

exports.createChangeSet = createChangeSet;

exports.extractChangesFromTweets = extractChangesFromTweets;

exports.getTweets = getTweets;

exports.search = search;

exports.timeline = timeline;

exports.transformChangeset = transformChangeset;
