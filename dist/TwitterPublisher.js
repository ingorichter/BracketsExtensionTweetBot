
/*
 * BracketsExtensionTweetBot
 * http://github.com/ingorichter/BracketsExtensionTweetBot
 *
 * Copyright (c) 2014 Ingo Richter
 * Licensed under the MIT license.
 */
'use strict';
var Promise, Twit, TwitterPublisher;

Promise = require('bluebird');

Twit = require('twit');

module.exports = TwitterPublisher = (function() {
  function TwitterPublisher(config) {
    this.twitterClient = new Twit(config);
  }

  TwitterPublisher.prototype.setClient = function(client) {
    return this.twitterClient = client;
  };

  TwitterPublisher.prototype.post = function(tweet) {
    return new Promise(function(resolve, reject) {
      return this.twitterClient.post('statuses/update', {
        status: tweet
      }, function(err, reply, response) {
        if (err) {
          return reject(err);
        } else {
          return resolve(reply);
        }
      });
    });
  };

  TwitterPublisher.prototype.userTimeLine = function(max_id, count) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var options;
        options = {};
        if (max_id != null) {
          options.max_id = max_id;
        }
        if (count != null) {
          options.count = count;
        }
        return _this.twitterClient.get('statuses/home_timeline', options, function(err, reply, response) {
          if (err) {
            return reject(err);
          } else {
            return resolve(reply);
          }
        });
      };
    })(this));
  };

  TwitterPublisher.prototype.search = function(query, untilDate) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var options;
        options = {};
        options.q = query;
        if (untilDate) {
          options.until = untilDate;
        }
        return _this.twitterClient.get('search/tweets', options, function(err, reply, response) {
          if (err) {
            return reject(err);
          } else {
            return resolve(reply);
          }
        });
      };
    })(this));
  };

  return TwitterPublisher;

})();
