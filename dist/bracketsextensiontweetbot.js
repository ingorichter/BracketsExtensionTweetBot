/*
 * BracketsExtensionTweetBot
 * http://github.com/ingorichter/BracketsExtensionTweetBot
 *
 * Copyright (c) 2014 Ingo Richter
 * Licensed under the MIT license.
*/


(function() {
  'use strict';
  var BRACKETS_REGISTRY_JSON, REGISTRY_JSON, T, TWITTER_CONFIG, Twit, createChangeset, createNotification, downloadExtensionRegistry, fs, https, loadLocalRegistry, path, promise, readFile, request, rockAndRoll, swapRegistryFiles, tweet, twitterConf, writeFile, zlib,
    __hasProp = {}.hasOwnProperty;

  fs = require("fs");

  path = require("path");

  zlib = require("zlib");

  https = require("https");

  promise = require("bluebird");

  readFile = promise.promisify(require("fs").readFile);

  writeFile = promise.promisify(require("fs").writeFile);

  request = require("request");

  Twit = require('twit');

  BRACKETS_REGISTRY_JSON = "https://s3.amazonaws.com/extend.brackets/registry.json";

  TWITTER_CONFIG = path.resolve(__dirname, '../twitterconfig.json');

  REGISTRY_JSON = path.resolve(__dirname, '../extensionRegistry.json');

  twitterConf = JSON.parse(fs.readFileSync(TWITTER_CONFIG));

  loadLocalRegistry = function() {
    var deferred, p;
    deferred = promise.defer();
    p = readFile(REGISTRY_JSON);
    p.then(function(data) {
      return deferred.resolve(JSON.parse(data));
    });
    p["catch"](function(err) {
      if (err.cause.errno === 34) {
        return deferred.resolve({});
      } else {
        return deferred.reject(err);
      }
    });
    return deferred.promise;
  };

  downloadExtensionRegistry = function() {
    var deferred;
    deferred = promise.defer();
    request({
      uri: BRACKETS_REGISTRY_JSON,
      json: true,
      encoding: null
    }, function(err, resp, body) {
      if (err) {
        deferred.reject(err);
      } else {
        zlib.gunzip(body, function(err, buffer) {
          if (err) {
            console.error(err);
            deferred.reject(err);
          } else {
            deferred.resolve(JSON.parse(buffer.toString()));
          }
        });
      }
    });
    return deferred.promise;
  };

  createChangeset = function(oldRegistry, newRegistry) {
    var changeRecord, changesets, extension, extensionName, previousExtension, type;
    changesets = [];
    for (extensionName in newRegistry) {
      if (!__hasProp.call(newRegistry, extensionName)) continue;
      extension = newRegistry[extensionName];
      previousExtension = oldRegistry != null ? oldRegistry[extensionName] : void 0;
      if (previousExtension) {
        if (extension.versions.length > previousExtension.versions.length) {
          type = "UPDATE";
        }
        if (extension.versions.length === previousExtension.versions.length) {
          type = void 0;
        }
      } else {
        type = "NEW";
      }
      if (type === "UPDATE" || type === "NEW") {
        changeRecord = {
          type: type,
          title: extension.metadata.title,
          version: extension.metadata.version,
          downloadUrl: 'https://s3.amazonaws.com/extend.brackets/' + extension.metadata.name + "/" + extension.metadata.name + "-" + extension.metadata.version + ".zip",
          description: extension.metadata.description
        };
        changesets.push(changeRecord);
      }
    }
    return changesets;
  };

  createNotification = function(changeRecord) {
    return "" + changeRecord.title + " - " + changeRecord.version + " (" + changeRecord.type + ") " + changeRecord.downloadUrl + " @brackets";
  };

  T = new Twit(twitterConf);

  tweet = function(data) {
    T.post('statuses/update', {
      status: data
    }, function(err, reply) {
      if (err) {
        return console.log(err);
      }
    });
  };

  swapRegistryFiles = function(newContent) {
    var d, extRegBackupDir;
    extRegBackupDir = path.resolve(__dirname, "../.oldExtensionRegistries");
    if (!fs.existsSync(extRegBackupDir)) {
      fs.mkdirSync(extRegBackupDir);
    }
    d = new Date();
    fs.createReadStream(REGISTRY_JSON).pipe(fs.createWriteStream(path.join(extRegBackupDir, "" + (d.getTime()) + "-extensionRegistry.json")));
    fs.writeFileSync(REGISTRY_JSON, JSON.stringify(newContent));
  };

  rockAndRoll = function() {
    return loadLocalRegistry().then(function(oldRegistry) {
      return downloadExtensionRegistry().then(function(newRegistry) {
        var notification, notifications, _i, _len;
        notifications = createChangeset(oldRegistry, newRegistry).map(function(changeRecord) {
          return createNotification(changeRecord);
        });
        for (_i = 0, _len = notifications.length; _i < _len; _i++) {
          notification = notifications[_i];
          tweet(notification);
        }
        return swapRegistryFiles(newRegistry);
      });
    });
  };

  exports.createChangeset = createChangeset;

  exports.createNotification = createNotification;

  exports.tweet = tweet;

  exports.rockAndRoll = rockAndRoll;

}).call(this);
