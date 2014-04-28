
/*
 * BracketsExtensionTweetBot
 * http://github.com/ingorichter/BracketsExtensionTweetBot
 *
 * Copyright (c) 2014 Ingo Richter
 * Licensed under the MIT license.
 */

(function() {
  'use strict';
  var Twit, TwitterPublisher, promise;

  promise = require('bluebird');

  Twit = require('twit');

  module.exports = TwitterPublisher = (function() {
    function TwitterPublisher(config) {
      this.twitterClient = new Twit(config);
    }

    TwitterPublisher.prototype.post = function(tweet) {
      var deferred;
      deferred = promise.defer();
      this.twitterClient.post('statuses/update', {
        status: tweet
      }, function(err, reply, response) {
        if (err) {
          return deferred.reject(err);
        } else {
          return deferred.resolve(reply);
        }
      });
      return deferred.promise;
    };

    TwitterPublisher.prototype.userTimeLine = function() {
      var deferred;
      deferred = promise.defer();
      this.twitterClient.get('statuses/home_timeline', function(err, reply, response) {
        if (err) {
          return deferred.reject(err);
        } else {
          return deferred.resolve(reply);
        }
      });
      return deferred.promise;
    };

    TwitterPublisher.prototype.search = function(query, untilDate) {
      var deferred, options;
      deferred = promise.defer();
      options = {};
      options.q = query;
      if (untilDate) {
        options.until = untilDate;
      }
      this.twitterClient.get('search/tweets', options, function(err, reply, response) {
        if (err) {
          return deferred.reject(err);
        } else {
          return deferred.resolve(reply);
        }
      });
      return deferred.promise;
    };

    return TwitterPublisher;

  })();

}).call(this);
