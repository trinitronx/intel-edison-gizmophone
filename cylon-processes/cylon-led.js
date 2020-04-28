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
    relay: { driver: 'relay', pin: 6, type: 'closed', connection: 'edison' }
  },

  work: function(my) {
    every((1).second(), function() {
      my.relay.toggle();
      console.log("Relay: %j", 'toggled');
    });
  }
}).start();

//     button: { pin: 4, connection: 'edison' },

Cylon.start();
