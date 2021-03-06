var Cylon = require('cylon');

// Using a single function to handle multiple signals
const exitHandler = function handle(signal) {
  console.log(`Received ${signal}`);
  console.log(`Exiting gracefully...`);
  process.exit(0);
}

process.on('SIGINT', exitHandler.bind(null,'SIGINT'));
process.on('SIGTERM', exitHandler.bind(null,'SIGTERM'));
process.on('SIGHUP', exitHandler.bind(null,'SIGHUP'));

Cylon
  .robot()
  .connection('edison', { adaptor: 'intel-iot' })
  .device('button', { driver: 'button', pin: 4, connection: 'edison' })
  .device('led', { driver: 'led', pin: 13 , connection: 'edison' })
  .device('relay', { driver: 'relay', pin: 6, type: 'closed', connection: 'edison' })
  .on('ready', function(my) {
    my.button.on('push', function() {
      console.log('on');
      my.led.turnOn();
    });

    my.button.on('release', function() {
      console.log('off');
      my.led.turnOff();
    });
  });
Cylon.start();
