var dateFrom, dateTo, es, moment;

es = require('./ExtensionStats');

moment = require('moment');

if (process.argv.length < 3) {
  process.exit(1);
}

dateTo = moment(new Date(process.argv[3]));

dateTo.hours(2);

dateTo.minutes(0);

dateTo.seconds(0);

dateFrom = moment(dateTo);

dateFrom.subtract(7, 'days');

dateFrom.seconds(1);

es.extractChangesFromRegistry(dateFrom.toDate(), dateTo.toDate()).then(function(changeset) {
  var markdown;
  markdown = es.transfromRegistryChangeset(changeset);
  return console.log(markdown);
});
