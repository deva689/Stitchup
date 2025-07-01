var logger = require('../index');
if (require('is-browser')) {
  logger.intercept();

  console.log('this happpened', 123, [456]);
  console.log('that happpened', {a: 'b', b: 123});

  logger.connect({
    url: 'http://localhost:9999',
    sourceName: 'test-app'
  });
}
