
/*
 * BracketsExtensionTweetBot
 * http://github.com/ingorichter/BracketsExtensionTweetBot
 *
 * Copyright (c) 2014 Ingo Richter
 * Licensed under the MIT license.
 */
'use strict';
var BRACKETS_REGISTRY_JSON, Promise, REGISTRY_BASEURL, downloadExtensionRegistry, fs, request, zlib;

Promise = require('bluebird');

request = require('request');

zlib = require('zlib');

fs = require('fs');

REGISTRY_BASEURL = 'https://s3.amazonaws.com/extend.brackets';

BRACKETS_REGISTRY_JSON = REGISTRY_BASEURL + "/registry.json";

downloadExtensionRegistry = function() {
  return new Promise(function(resolve, reject) {
    return request({
      uri: BRACKETS_REGISTRY_JSON,
      json: true,
      encoding: null
    }, function(err, resp, body) {
      if (err) {
        return reject(err);
      } else {
        return fs.writeFile('./extensionRegistry.json.gz', body, function(err) {
          if (err) {
            return reject(err);
          } else {
            return zlib.gunzip(body, function(err, buffer) {
              if (err) {
                return reject(err);
              } else {
                return resolve(JSON.parse(buffer.toString()));
              }
            });
          }
        });
      }
    });
  });
};

exports.downloadExtensionRegistry = downloadExtensionRegistry;
