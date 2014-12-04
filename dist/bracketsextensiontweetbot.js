
/*
 * BracketsExtensionTweetBot
 * http://github.com/ingorichter/BracketsExtensionTweetBot
 *
 * Copyright (c) 2014 Ingo Richter
 * Licensed under the MIT license.
 */
'use strict';
var NOTIFICATION_TYPE, Promise, REGISTRY_BASEURL, REGISTRY_JSON, RegistryUtils, TWITTER_CONFIG, TwitterPublisher, createChangeset, createNotification, downloadUrl, fs, https, loadLocalRegistry, loadTwitterConfig, path, rockAndRoll, swapRegistryFiles, _,
  __hasProp = {}.hasOwnProperty;

path = require('path');

https = require('https');

Promise = require('bluebird');

fs = Promise.promisifyAll(require('fs'));

TwitterPublisher = require('./TwitterPublisher');

RegistryUtils = require('./RegistryUtils');

_ = require("lodash");

NOTIFICATION_TYPE = {
  'UPDATE': 'UPDATE',
  'NEW': 'NEW'
};

REGISTRY_BASEURL = 'https://s3.amazonaws.com/extend.brackets';

TWITTER_CONFIG = path.resolve(__dirname, '../twitterconfig.json');

REGISTRY_JSON = path.resolve(__dirname, '../extensionRegistry.json');

loadLocalRegistry = function(registry) {
  return new Promise(function(resolve, reject) {
    var p;
    registry = registry || REGISTRY_JSON;
    p = fs.readFileAsync(registry).then(function(data) {
      return resolve(JSON.parse(data));
    });
    return p["catch"](function(err) {
      if (err.cause.errno === 34) {
        return resolve({});
      } else {
        return reject(err);
      }
    });
  });
};

loadTwitterConfig = function() {
  return new Promise(function(resolve, reject) {
    var p, registry;
    registry = registry || REGISTRY_JSON;
    p = fs.readFileAsync(registry).then(function(data) {
      return resolve(JSON.parse(data));
    });
    return p["catch"](function(err) {
      if (err.cause.errno === 34) {
        return resolve({});
      } else {
        return reject(err);
      }
    });
  });
};

downloadUrl = function(extension) {
  return "" + REGISTRY_BASEURL + "/" + extension.metadata.name + "/" + extension.metadata.name + "-" + extension.metadata.version + ".zip";
};

createChangeset = function(oldRegistry, newRegistry) {
  var changeRecord, changesets, extension, extensionName, previousExtension, previousVersionsCount, type, _homepage, _ref, _ref1;
  changesets = [];
  for (extensionName in newRegistry) {
    if (!__hasProp.call(newRegistry, extensionName)) continue;
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
      _homepage = extension.metadata.homepage;
      if (!_homepage) {
        _homepage = (_ref = extension.metadata.repository) != null ? _ref.url : void 0;
      }
      changeRecord = {
        type: type,
        title: (_ref1 = extension.metadata.title) != null ? _ref1 : extension.metadata.name,
        version: extension.metadata.version,
        downloadUrl: downloadUrl(extension),
        description: extension.metadata.description,
        homepage: _homepage != null ? _homepage : ""
      };
      changesets.push(changeRecord);
    }
  }
  return changesets;
};

createNotification = function(changeRecord) {
  return "" + changeRecord.title + " - " + changeRecord.version + " (" + changeRecord.type + ") " + changeRecord.homepage + " " + changeRecord.downloadUrl + " @brackets";
};

swapRegistryFiles = function(newContent) {
  var d, extRegBackupDir;
  extRegBackupDir = path.resolve(__dirname, "../.oldExtensionRegistries");
  if (!fs.existsSync(extRegBackupDir)) {
    fs.mkdirSync(extRegBackupDir);
  }
  d = new Date();
  fs.createReadStream(REGISTRY_JSON).pipe(fs.createWriteStream(path.join(extRegBackupDir, "" + (d.getTime()) + "-extensionRegistry.json")));
  return fs.writeFileSync(REGISTRY_JSON, JSON.stringify(newContent));
};

rockAndRoll = function() {
  return new Promise(function(resolve, reject) {
    return Promise.join(loadLocalRegistry(), RegistryUtils.downloadExtensionRegistry(), function(oldRegistry, newRegistry) {
      var notifications;
      notifications = createChangeset(oldRegistry, newRegistry).map(function(changeRecord) {
        return createNotification(changeRecord);
      });
      return fs.readFile(TWITTER_CONFIG, function(err, data) {
        var notification, twitterConf, twitterPublisher, _i, _len;
        if (err && err.errno === 34) {
          data = "{\"empty\": true}";
        } else {
          reject(err);
        }
        twitterConf = JSON.parse(data);
        twitterPublisher = new TwitterPublisher(twitterConf);
        for (_i = 0, _len = notifications.length; _i < _len; _i++) {
          notification = notifications[_i];
          twitterPublisher.post(notification);
        }
        swapRegistryFiles(newRegistry);
        return resolve();
      });
    });
  });
};

exports.createChangeset = createChangeset;

exports.createNotification = createNotification;

exports.rockAndRoll = rockAndRoll;

exports.loadLocalRegistry = loadLocalRegistry;
