
/*
 * BracketsExtensionTweetBot
 * http://github.com/ingorichter/BracketsExtensionTweetBot
 *
 * Copyright (c) 2014 Ingo Richter
 * Licensed under the MIT license.
 */
'use strict';
var NOTIFICATION_TYPE, Promise, REGISTRY_BASEURL, REGISTRY_JSON, RegistryUtils, TWITTER_CONFIG, TwitterPublisher, _, createChangeset, createNotification, downloadUrl, fs, https, loadLocalRegistry, path, rockAndRoll, swapRegistryFiles, zlib,
  hasProp = {}.hasOwnProperty;

path = require('path');

https = require('https');

Promise = require('bluebird');

fs = Promise.promisifyAll(require('fs'));

TwitterPublisher = require('./TwitterPublisher');

RegistryUtils = require('./RegistryUtils');

_ = require('lodash');

zlib = require('zlib');

NOTIFICATION_TYPE = {
  'UPDATE': 'UPDATE',
  'NEW': 'NEW'
};

REGISTRY_BASEURL = 'https://s3.amazonaws.com/extend.brackets';

TWITTER_CONFIG = path.resolve(__dirname, '../twitterconfig.json');

REGISTRY_JSON = path.resolve(__dirname, '../extensionRegistry.json.gz');

loadLocalRegistry = function(registry) {
  return new Promise(function(resolve, reject) {
    var p;
    registry = registry || REGISTRY_JSON;
    p = fs.readFileAsync(registry).then(function(data) {
      return zlib.gunzip(data, function(err, buffer) {
        if (err) {
          return reject(err);
        } else {
          return resolve(JSON.parse(buffer.toString()));
        }
      });
    });
    return p["catch"](function(err) {
      if (err.cause.code === "ENOENT") {
        return resolve({});
      } else {
        return reject(err);
      }
    });
  });
};

downloadUrl = function(extension) {
  return REGISTRY_BASEURL + "/" + extension.metadata.name + "/" + extension.metadata.name + "-" + extension.metadata.version + ".zip";
};

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
      _homepage = extension.metadata.homepage;
      if (!_homepage) {
        _homepage = (ref = extension.metadata.repository) != null ? ref.url : void 0;
      }
      changeRecord = {
        type: type,
        title: (ref1 = extension.metadata.title) != null ? ref1 : extension.metadata.name,
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
  return changeRecord.title + " - " + changeRecord.version + " (" + changeRecord.type + ") " + changeRecord.homepage + " " + changeRecord.downloadUrl + " @brackets";
};

swapRegistryFiles = function(newContent) {
  return new Promise(function(resolve, reject) {
    var d, extRegBackupDir, gzip;
    extRegBackupDir = path.resolve(__dirname, "../.oldExtensionRegistries");
    if (!fs.existsSync(extRegBackupDir)) {
      fs.mkdirSync(extRegBackupDir);
    }
    d = new Date();
    gzip = zlib.createGzip();
    fs.createReadStream(REGISTRY_JSON).pipe(gzip).pipe(fs.createWriteStream(path.join(extRegBackupDir, (d.getTime()) + "-extensionRegistry.json.gz")));
    return zlib.gzip(JSON.stringify(newContent), function(err, buffer) {
      if (err) {
        return reject(err);
      } else {
        return fs.writeFile(REGISTRY_JSON, buffer, function(err) {
          if (err) {
            return reject(err);
          } else {
            return resolve();
          }
        });
      }
    });
  });
};

rockAndRoll = function() {
  return new Promise(function(resolve, reject) {
    return Promise.join(loadLocalRegistry(), RegistryUtils.downloadExtensionRegistry(), function(oldRegistry, newRegistry) {
      var notifications;
      notifications = createChangeset(oldRegistry, newRegistry).map(function(changeRecord) {
        return createNotification(changeRecord);
      });
      return fs.readFile(TWITTER_CONFIG, function(err, data) {
        var i, len, notification, twitterConf, twitterPublisher;
        if (err) {
          if (err.code === "ENOENT") {
            data = "{\"empty\": true}";
          } else {
            reject(err);
          }
        }
        twitterConf = JSON.parse(data);
        twitterPublisher = new TwitterPublisher(twitterConf);
        for (i = 0, len = notifications.length; i < len; i++) {
          notification = notifications[i];
          twitterPublisher.post(notification);
        }
        return swapRegistryFiles(newRegistry).then(function() {
          return resolve();
        });
      });
    });
  });
};

exports.createChangeset = createChangeset;

exports.createNotification = createNotification;

exports.rockAndRoll = rockAndRoll;

exports.loadLocalRegistry = loadLocalRegistry;
