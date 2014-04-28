# BracketsExtensionTweetBot [![Build Status](https://secure.travis-ci.org/ingorichter/BracketsExtensionTweetBot.svg?branch=master)](http://travis-ci.org/ingorichter/BracketsExtensionTweetBot)

Tweet about new and updated Brackets extensions

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

## Contributing
In lieu of a formal styleguide, take care to maintain the existing coding style. Add unit tests for any new or changed functionality. Lint and test your code using [Grunt](http://gruntjs.com/).

## Release History
- 0.0.2 - Minor fixes and code cleanup
- 0.0.1 - Initial Release

## License
Copyright (c) 2014 Ingo Richter. Licensed under the MIT license.
