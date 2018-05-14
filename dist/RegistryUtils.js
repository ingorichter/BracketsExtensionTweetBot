/*
 * BracketsExtensionTweetBot
 * http://github.com/ingorichter/BracketsExtensionTweetBot
 *
 * Copyright (c) 2014 Ingo Richter
 * Licensed under the MIT license.
 */
// jslint vars: true, plusplus: true, devel: true, node: true, nomen: true, indent: 4, maxerr: 50
'use strict';
var BRACKETS_REGISTRY_JSON_URL, Promise, REGISTRY_BASEURL, REGISTRY_SNAPSHOT_FILE_LATEST, REGISTRY_SNAPSHOT_FILE_PREVIOUS, REGISTRY_SNAPSHOT_LOCATION_DIR, axios, dotenv, downloadExtensionRegistry, extensionDownloadURL, fs, loadLocalRegistry, path, swapRegistryFiles, zlib;

Promise = require('bluebird');

axios = require('axios');

zlib = require('zlib');

fs = Promise.promisifyAll(require('fs'));

path = require('path');

dotenv = require('dotenv-safe');

dotenv.config();

// config
REGISTRY_BASEURL = "https://s3.amazonaws.com/extend.brackets";

BRACKETS_REGISTRY_JSON_URL = `${REGISTRY_BASEURL}/registry.json`;

// local
REGISTRY_SNAPSHOT_LOCATION_DIR = process.env.REGISTRY_SNAPSHOT_LOCATION_DIR;

REGISTRY_SNAPSHOT_FILE_LATEST = path.resolve(REGISTRY_SNAPSHOT_LOCATION_DIR, "extensionRegistry.json.gz.new");

REGISTRY_SNAPSHOT_FILE_PREVIOUS = path.resolve(REGISTRY_SNAPSHOT_LOCATION_DIR, "extensionRegistry.json.gz.previous");

downloadExtensionRegistry = function() {
  return new Promise(async function(resolve, reject) {
    var e, response;
    try {
      response = (await axios.get(BRACKETS_REGISTRY_JSON_URL));
      return zlib.gzip(JSON.stringify(response.data), async function(err, buffer) {
        var error;
        if (err) {
          return reject(err);
        } else {
          try {
            await fs.writeFileAsync(REGISTRY_SNAPSHOT_FILE_LATEST, buffer);
            return resolve(response.data);
          } catch (error1) {
            error = error1;
            return reject(error);
          }
        }
      });
    } catch (error1) {
      e = error1;
      return reject(e);
    }
  });
};

// helper to create a canonical URL to download the extension
extensionDownloadURL = function(extension) {
  return `${REGISTRY_BASEURL}/${extension.metadata.name}/${extension.metadata.name}-${extension.metadata.version}.zip`;
};

loadLocalRegistry = function(registry) {
  return new Promise(function(resolve, reject) {
    var p;
    registry = registry || REGISTRY_SNAPSHOT_FILE_PREVIOUS;
    p = fs.readFileAsync(registry).then(function(data) {
      return zlib.gunzip(data, function(err, buffer) {
        if (err) {
          return reject(err);
        } else {
          return resolve(JSON.parse(buffer.toString()));
        }
      });
    });
    return p.catch(function(err) {
      //# file doesn't exist
      if (err.cause.code === "ENOENT") {
        return resolve({});
      } else {
        return reject(err);
      }
    });
  });
};

swapRegistryFiles = function(newContent) {
  return new Promise(async function(resolve, reject) {
    var archiveRegistryName, d, error;
    if (!fs.existsSync(REGISTRY_SNAPSHOT_LOCATION_DIR)) {
      // TODO(Ingo): the directory check needs to be more central
      fs.mkdirSync(REGISTRY_SNAPSHOT_LOCATION_DIR);
    }
    // create timestamp for archived registry
    d = new Date();
    archiveRegistryName = `${d.getTime()}-extensionRegistry.json.gz`;
    try {
      await fs.renameAsync(REGISTRY_SNAPSHOT_FILE_PREVIOUS, path.join(REGISTRY_SNAPSHOT_LOCATION_DIR, archiveRegistryName));
      await fs.renameAsync(REGISTRY_SNAPSHOT_FILE_LATEST, REGISTRY_SNAPSHOT_FILE_PREVIOUS);
      return resolve();
    } catch (error1) {
      error = error1;
      try {
        await fs.renameAsync(REGISTRY_SNAPSHOT_FILE_LATEST, REGISTRY_SNAPSHOT_FILE_PREVIOUS);
        return resolve();
      } catch (error1) {
        error = error1;
        return resolve(error);
      }
    }
  });
};

// API
exports.downloadExtensionRegistry = downloadExtensionRegistry;

exports.extensionDownloadURL = extensionDownloadURL;

exports.loadLocalRegistry = loadLocalRegistry;

exports.swapRegistryFiles = swapRegistryFiles;
