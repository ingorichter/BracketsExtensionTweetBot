
/*
 * ExtensionStats
 * http://github.com/ingorichter/BracketsExtensionTweetBot
 *
 * Copyright (c) 2014 Ingo Richter
 * Licensed under the MIT license.
 */
'use strict';
var BRACKETS_REGISTRY_JSON, DEFAULT_NUMBER_OF_DAYS, DateRange, NEW_KEY, Promise, REGISTRY_BASEURL, RegistryFormatter, RegistryUtils, TWITTER_CONFIG, TweetFormatter, TwitterPublisher, UPDATE_KEY, _, createChangeSet, createChangeSetFromRegistry, extractChangesFromRegistry, extractChangesFromTweets, filter, filterRegistry, fs, getRegistry, getTweets, getTweetsFromRange, path, request, search, timeline, transformChangeset, transfromRegistryChangeset, twitterPublisher, zlib;

path = require('path');

fs = require('fs');

Promise = require('bluebird');

request = require('request');

zlib = require('zlib');

TwitterPublisher = require('./TwitterPublisher');

TweetFormatter = require('./TweetFormatter');

RegistryFormatter = require('./RegistryFormatter');

RegistryUtils = require('./RegistryUtils');

_ = require('lodash');

TWITTER_CONFIG = path.resolve(__dirname, '../twitterconfig.json');

twitterPublisher = void 0;

DEFAULT_NUMBER_OF_DAYS = 7;

UPDATE_KEY = "UPDATE";

NEW_KEY = "NEW";

REGISTRY_BASEURL = 'https://s3.amazonaws.com/extend.brackets';

BRACKETS_REGISTRY_JSON = REGISTRY_BASEURL + "/registry.json";

DateRange = (function() {
  function DateRange(from1, to1) {
    this.from = from1;
    this.to = to1;
  }

  DateRange.prototype.contains = function(date) {
    var ref;
    return (this.from.getTime() <= (ref = date.getTime()) && ref <= this.to.getTime());
  };

  return DateRange;

})();

createChangeSet = function(tweets) {
  var newExtensions, tweet, updatedExtensions;
  newExtensions = (function() {
    var i, len, results;
    results = [];
    for (i = 0, len = tweets.length; i < len; i++) {
      tweet = tweets[i];
      if (tweet.text.indexOf("(NEW)") > -1) {
        results.push(tweet);
      }
    }
    return results;
  })();
  updatedExtensions = (function() {
    var i, len, results;
    results = [];
    for (i = 0, len = tweets.length; i < len; i++) {
      tweet = tweets[i];
      if (tweet.text.indexOf("(UPDATE)") > -1) {
        results.push(tweet);
      }
    }
    return results;
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
  var _tweets, allTweets, deferred, lastTweetDate, startDate;
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
      var i, j, len, len1, tweet;
      lastTweetDate = new Date(tweets[tweets.length - 1].created_at).getTime();
      if (lastTweetDate > startDate) {
        for (i = 0, len = tweets.length; i < len; i++) {
          tweet = tweets[i];
          allTweets.push(tweet);
        }
        return _tweets(tweets[tweets.length - 1].id, count);
      } else {
        for (j = 0, len1 = tweets.length; j < len1; j++) {
          tweet = tweets[j];
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

getRegistry = function() {
  return RegistryUtils.downloadExtensionRegistry();
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
    return getRegistry().then(function(json) {
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

exports.getRegistry = getRegistry;

exports.search = search;

exports.timeline = timeline;

exports.transformChangeset = transformChangeset;

exports.transfromRegistryChangeset = transfromRegistryChangeset;
