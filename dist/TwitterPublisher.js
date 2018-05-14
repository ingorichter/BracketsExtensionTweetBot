/*
 * BracketsExtensionTweetBot
 * http://github.com/ingorichter/BracketsExtensionTweetBot
 *
 * Copyright (c) 2014 Ingo Richter
 * Licensed under the MIT license.
 */
// jslint vars: true, plusplus: true, devel: true, node: true, nomen: true, indent: 4, maxerr: 50
'use strict';
var Promise, Twit, TwitterPublisher;

Promise = require('bluebird');

Twit = require('twit');

module.exports = TwitterPublisher = class TwitterPublisher {
  constructor(config) {
    this.twitterClient = new Twit(config);
  }

  setClient(client) {
    return this.twitterClient = client;
  }

  post(tweet) {
    return new Promise((resolve, reject) => {
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
  }

  // https://dev.twitter.com/docs/api/1.1/get/statuses/user_timeline
  // count - default is 20 defined by the twitter API
  // @param {?String} max_id - results lower or equal to max_id (to get older posts)
  userTimeLine(max_id, count) {
    return new Promise((resolve, reject) => {
      var options;
      options = {};
      if (max_id != null) {
        options.max_id = max_id;
      }
      if (count != null) {
        options.count = count;
      }
      return this.twitterClient.get('statuses/home_timeline', options, function(err, reply, response) {
        if (err) {
          return reject(err);
        } else {
          return resolve(reply);
        }
      });
    });
  }

  search(query, untilDate) {
    return new Promise((resolve, reject) => {
      var options;
      options = {};
      options.q = query;
      if (untilDate) {
        options.until = untilDate;
      }
      return this.twitterClient.get('search/tweets', options, function(err, reply, response) {
        if (err) {
          return reject(err);
        } else {
          return resolve(reply);
        }
      });
    });
  }

};
