var Cylon = require('cylon');

Cylon.robot({
  connections: {
    edison: { adaptor:  'intel-iot'}
  },

  devices: {
    pin: { driver: 'direct-pin', pin: 8 }
  },

  work: function(my) {
    var value = 0;
    every((1).second(), function() {
      my.pin.digitalWrite(value);
      value = (value == 0) ? 1 : 0;
    });
  }
}).start();