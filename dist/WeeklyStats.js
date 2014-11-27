var es;

es = require('./ExtensionStats');

es.extractChangesFromRegistry(new Date(2014, 10, 10, 2, 0, 1), new Date(2014, 10, 17, 2, 0, 0)).then(function(changeset) {
  var markdown;
  markdown = es.transfromRegistryChangeset(changeset);
  return console.log(markdown);
});
