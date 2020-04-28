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


Cylon.robot({
  connections: {
    edison: { adaptor: 'intel-iot' }
  },

  devices: {
    button: { driver: 'button', pin: 4, connection: 'edison' },
    led: { driver: 'led', pin: 13, connection: 'edison' }
  },

  work: function(my) {
    my.button.on('push', function() {
      my.led.turnOn();
      console.log("button on");
    });
    my.button.on('release', function() {
      my.led.turnOff();
      console.log("button off");
    });
  }
}).start();


Cylon.start();
