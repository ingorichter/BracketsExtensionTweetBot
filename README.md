# BracketsExtensionTweetBot

[![Build Status](https://travis-ci.org/ingorichter/BracketsExtensionTweetBot.svg?branch=master)](http://travis-ci.org/ingorichter/BracketsExtensionTweetBot)[![NPM Dependencies](https://david-dm.org/ingorichter/BracketsExtensionTweetBot.svg?style=flat)](https://david-dm.org/ingorichter/BracketsExtensionTweetBot)

Tweet about new and updated Brackets extensions

## How does it work
The Brackets project hosts a database of extensions https://registry.brackets.io/. The registry can be downloaded as gzipped json file with all meta data for every extension. This snapshot will be used to determine the delta to an older version of the registry.
This Bot is downloading a registry snapshot and compares it with a previous version of a registry snapshot to find the extensions that have been added, deleted or updated.

Once the delta has been determined, the latest registry will be archived into another directory. This is done to have some historic data, since the official registry doesn't archive and version their entries.

## Download Registry Snapshot
To determine the delta between two bot runs the bot needs two snapshots of the extensions registry.
The new snapshot of the registry will be downloaded to ${REGISTRY_SNAPSHOT_LOCATION_DIR} as `extensionRegistry-latest.json.gz`.

The bot creates the delta between `extensionRegistry-latest.json.gz` and the previous version `
## Getting Started
This is the tweet bot to announce new and updated @Brackets extensions.

## Configuration
The Bot requires a configuration to post to twitter. A json file `twitterconfig.json` in the root of the project is required to post to twitter.

The file needs the following information:
```
{
    "consumer_key":         "SECRET_KEY",
    "consumer_secret":      "CONSUMER_SECRET",
    "access_token":         "ACCESS_TOKEN",
    "access_token_secret":  "ACCESS_TOKEN_SECRET"
}
```

### Cronjob
I have a cronjob configured to run the Bot every hour of the day. This means the registry snapshots are all an hour apart from each other. This sort of granularity is enough to keep followers informed about updates without spamming them.

## Contributing
In lieu of a formal styleguide, take care to maintain the existing coding style. Add unit tests for any new or changed functionality. Lint and test your code using [Grunt](http://gruntjs.com/).

## Release History
- 0.0.2 - Minor fixes and code cleanup
- 0.0.1 - Initial Release

## License
Copyright (c) 2014 Ingo Richter. Licensed under the MIT license.
