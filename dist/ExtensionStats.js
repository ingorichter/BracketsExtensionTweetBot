
/*
 * BracketsExtensionTweetBot
 * http://github.com/ingorichter/BracketsExtensionTweetBot
 *
 * Copyright (c) 2014 Ingo Richter
 * Licensed under the MIT license.
 */
'use strict';
var BRACKETS_REGISTRY_JSON, DEFAULT_NUMBER_OF_DAYS, DateRange, NEW_KEY, Promise, REGISTRY_BASEURL, RegistryFormatter, TWITTER_CONFIG, TweetFormatter, TwitterPublisher, UPDATE_KEY, createChangeSet, createChangeSetFromRegistry, downloadExtensionRegistry, extractChangesFromRegistry, extractChangesFromTweets, filter, filterRegistry, fs, getJSON, getTweets, getTweetsFromRange, path, request, search, timeline, transformChangeset, transfromRegistryChangeset, twitterPublisher, zlib, _;

path = require('path');

fs = require('fs');

Promise = require('bluebird');

request = require('request');

zlib = require('zlib');

TwitterPublisher = require('./TwitterPublisher');

TweetFormatter = require('./TweetFormatter');

RegistryFormatter = require('./RegistryFormatter');

_ = require('lodash');

TWITTER_CONFIG = path.resolve(__dirname, '../twitterconfig.json');

twitterPublisher = void 0;

DEFAULT_NUMBER_OF_DAYS = 7;

UPDATE_KEY = "UPDATE";

NEW_KEY = "NEW";

REGISTRY_BASEURL = 'https://s3.amazonaws.com/extend.brackets';

BRACKETS_REGISTRY_JSON = "" + REGISTRY_BASEURL + "/registry.json";

DateRange = (function() {
  function DateRange(from, to) {
    this.from = from;
    this.to = to;
  }

  DateRange.prototype.contains = function(date) {
    var _ref;
    return (this.from.getTime() <= (_ref = date.getTime()) && _ref <= this.to.getTime());
  };

  return DateRange;

})();

downloadExtensionRegistry = function() {
  var deferred;
  deferred = Promise.defer();
  request({
    uri: BRACKETS_REGISTRY_JSON,
    json: true,
    encoding: null
  }, function(err, resp, body) {
    if (err) {
      return deferred.reject(err);
    } else {
      return zlib.gunzip(body, function(err, buffer) {
        if (err) {
          console.error(err);
          return deferred.reject(err);
        } else {
          return deferred.resolve(JSON.parse(buffer.toString()));
        }
      });
    }
  });
  return deferred.promise;
};

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
  var twitterConf;
  twitterConf = JSON.parse(fs.readFileSync(TWITTER_CONFIG));
  twitterPublisher = new TwitterPublisher(twitterConf);
  return getTweetsFromRange(from, to);
};

getJSON = function() {
  return new Promise(function(resolve, reject) {
    var p;
    p = downloadExtensionRegistry();
    p.then(function(json) {
      return resolve(json);
    });
    return p["catch"](function(err) {
      return reject(err);
    });
  });
};

filter = function(from, to, json) {
  var filteredRegistry;
  if (to == null) {
    to = new Date();
  }
  filteredRegistry = _.filter(json, function(item) {
    var pubDate, versions;
    versions = item.versions.length;
    pubDate = new Date(item.versions[versions - 1].published).getTime();
    return pubDate >= from.getTime() && pubDate <= to.getTime();
  });
  return filteredRegistry;
};

createChangeSetFromRegistry = function(registry) {
  var newExtensions, updatedExtensions;
  newExtensions = _.filter(registry, function(extension) {
    return extension.versions.length === 1;
  });
  updatedExtensions = _.filter(registry, function(extension) {
    return extension.versions.length !== 1;
  });
  if ((newExtensions.length + updatedExtensions.length) !== registry.length) {
    console.warn("Mismatch");
  }
  return {
    "NEW": newExtensions,
    "UPDATE": updatedExtensions
  };
};

filterRegistry = function(from, to) {
  return new Promise(function(resolve, reject) {
    return getJSON().then(function(json) {
      return resolve(filter(from, to, json));
    });
  });
};

extractChangesFromTweets = function(from, to) {
  return new Promise(function(resolve, reject) {
    return getTweets(from, to).then(function(tweets) {
      var cs;
      cs = createChangeSet(tweets);
      return resolve(cs);
    });
  });
};

extractChangesFromRegistry = function(from, to) {
  return filterRegistry(from, to).then(function(filteredRegistry) {
    return createChangeSetFromRegistry(filteredRegistry);
  });
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

transformChangeset = function(changeSet) {
  var formatter;
  formatter = new TweetFormatter();
  return formatter.transform(changeSet);
};

transfromRegistryChangeset = function(changeSet) {
  var formatter;
  formatter = new RegistryFormatter();
  return formatter.transform(changeSet);
};

exports.createChangeSet = createChangeSet;

exports.createChangeSetFromRegistry = createChangeSetFromRegistry;

exports.extractChangesFromTweets = extractChangesFromTweets;

exports.extractChangesFromRegistry = extractChangesFromRegistry;

exports.filterRegistry = filterRegistry;

exports.getTweets = getTweets;

exports.getJSON = getJSON;

exports.search = search;

exports.timeline = timeline;

exports.transformChangeset = transformChangeset;

exports.transfromRegistryChangeset = transfromRegistryChangeset;
