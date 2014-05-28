var es;

es = require('./ExtensionStats');

es.extractChangesFromTweets(new Date(2014, 4, 26, 23, 0)).then(function(changeset) {
  var markdown;
  markdown = es.transformChangeset(changeset);
  return console.log(markdown);
});
