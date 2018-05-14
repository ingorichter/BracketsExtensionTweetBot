/*
 * BracketsExtensionTweetBot
 * http://github.com/ingorichter/BracketsExtensionTweetBot
 *
 * Copyright (c) 2014 Ingo Richter
 * Licensed under the MIT license.
 */
// jslint vars: true, plusplus: true, devel: true, node: true, nomen: true, indent: 4, maxerr: 50
'use strict';
var NOTIFICATION_TYPE, Promise, RegistryUtils, TwitterPublisher, createChangeset, createNotification, createTwitterConfig, dotenv, dryRun, dryRunTwitterClient, process, rockAndRoll,
  hasProp = {}.hasOwnProperty;

Promise = require('bluebird');

TwitterPublisher = require('./TwitterPublisher');

RegistryUtils = require('./RegistryUtils');

dotenv = require('dotenv-safe');

process = require('process');

dotenv.config();

NOTIFICATION_TYPE = {
  'UPDATE': 'UPDATE',
  'NEW': 'NEW'
};

dryRun = false;

if (process.argv.length === 3 && process.argv[2] === 'dryRun') {
  dryRun = true;
}

createChangeset = function(oldRegistry, newRegistry) {
  var _homepage, changeRecord, changesets, extension, extensionName, previousExtension, previousVersionsCount, ref, ref1, type;
  changesets = [];
  for (extensionName in newRegistry) {
    if (!hasProp.call(newRegistry, extensionName)) continue;
    extension = newRegistry[extensionName];
    previousExtension = oldRegistry != null ? oldRegistry[extensionName] : void 0;
    if (previousExtension) {
      previousVersionsCount = previousExtension.versions.length;
      if (extension.versions.length > previousVersionsCount) {
        type = NOTIFICATION_TYPE.UPDATE;
      }
      if (extension.versions.length === previousVersionsCount) {
        type = void 0;
      }
    } else {
      type = NOTIFICATION_TYPE.NEW;
    }
    if (type === NOTIFICATION_TYPE.UPDATE || type === NOTIFICATION_TYPE.NEW) {
      // determine what to provide for homepage if the homepage isn't available
      _homepage = extension.metadata.homepage;
      if (!_homepage) {
        _homepage = (ref = extension.metadata.repository) != null ? ref.url : void 0;
      }
      changeRecord = {
        type: type,
        title: (ref1 = extension.metadata.title) != null ? ref1 : extension.metadata.name,
        version: extension.metadata.version,
        downloadUrl: RegistryUtils.extensionDownloadURL(extension),
        description: extension.metadata.description,
        homepage: _homepage != null ? _homepage : ""
      };
      changesets.push(changeRecord);
    }
  }
  return changesets;
};

createTwitterConfig = function() {
  var twitterConf;
  twitterConf = {};
  twitterConf.consumer_key = process.env.TWITTER_CONSUMER_KEY;
  twitterConf.consumer_secret = process.env.TWITTER_CONSUMER_SECRET;
  twitterConf.access_token = process.env.TWITTER_ACCESS_TOKEN;
  twitterConf.access_token_secret = process.env.TWITTER_ACCESS_TOKEN_SECRET;
  return twitterConf;
};


// createNotification

createNotification = function(changeRecord) {
  return `${changeRecord.title} - ${changeRecord.version} (${changeRecord.type}) ${changeRecord.homepage} ${changeRecord.downloadUrl} @brackets`;
};


// dryRunTwitterClient for debugging and dry run testing

dryRunTwitterClient = function() {
  return dryRunTwitterClient = {
    post: function(endpoint, tweet) {
      // TODO(Ingo): replace with logging infrastructure
      console.log(tweet.status);
      return Promise.resolve(tweet.status);
    }
  };
};

// This is the main function
rockAndRoll = function() {
  return new Promise(function(resolve, reject) {
    return Promise.join(RegistryUtils.loadLocalRegistry(), RegistryUtils.downloadExtensionRegistry(), function(oldRegistry, newRegistry) {
      var i, len, notification, notifications, twitterConf, twitterPublisher;
      notifications = createChangeset(oldRegistry, newRegistry).map(function(changeRecord) {
        return createNotification(changeRecord);
      });
      twitterConf = createTwitterConfig();
      twitterPublisher = new TwitterPublisher(twitterConf);
      if (dryRun) {
        twitterPublisher.setClient(dryRunTwitterClient());
      }
      for (i = 0, len = notifications.length; i < len; i++) {
        notification = notifications[i];
        twitterPublisher.post(notification);
      }
      return RegistryUtils.swapRegistryFiles(newRegistry).then(function() {
        return resolve();
      });
    });
  });
};

// API
exports.createChangeset = createChangeset;

exports.createNotification = createNotification;

exports.createTwitterConfig = createTwitterConfig;

exports.rockAndRoll = rockAndRoll;
