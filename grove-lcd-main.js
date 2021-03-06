// Drive the Grive RGB LCD (a JHD1313m1)
//
// The way to drive the LCD directly from
// Javascript code using the i2c interface directly
// This approach is useful for learning about using
// the i2c bus. The i2c file is an implementation
// in Javascript for some of the common LCD functions

// configure jshint
/*jslint node:true, vars:true, bitwise:true, unparam:true */
/*jshint unused:true */

// we want mraa to be at least version 0.6.1
var mraa = require('mraa');
var version = mraa.getVersion();
var os = require("os");
var hostname = os.hostname();

if (version >= 'v0.6.1') {
    console.log('mraa version (' + version + ') ok');
}
else {
    console.log('meaa version(' + version + ') is old - this code may not work');
}

// Using a single function to handle multiple signals
const exitHandler = function handle(signal) {
  console.log(`Received ${signal}`);
  console.log(`Exiting gracefully...`);
  process.exit(0);
}

process.on('SIGINT', exitHandler.bind(null,'SIGINT'));
process.on('SIGTERM', exitHandler.bind(null,'SIGTERM'));
process.on('SIGHUP', exitHandler.bind(null,'SIGHUP'));

// process.on('SIGINT', exitHandler.bind('SIGINT'));
// process.on('SIGTERM', exitHandler('SIGTERM'));
// process.on('SIGHUP', exitHandler('SIGHUP'));



useLcd();


/**
 * Rotate through a color pallette and display the
 * color of the background as text
 */
function rotateColors(display) {
    var red = 0;
    var green = 0;
    var blue = 0;
    display.setColor(red, green, blue);
    setInterval(function() {
        blue += 64;
        if (blue > 255) {
            blue = 0;
            green += 64;
            if (green > 255) {
                green = 0;
                red += 64;
                if (red > 255) {
                    red = 0;
                }
            }
        }
        display.setColor(red, green, blue);
        display.setCursor(0,0);
        display.write(' ' + hostname);
        display.setCursor(1,0);
        display.write('r=' + red + ' g=' + green + ' ');
        display.write('b=' + blue + '           ');  // extra padding clears out previous text
    }, 1000);
}

/**
 * Use the hand rolled i2c.js code to do the
 * same thing as the previous code without the
 * upm library
 */
function useLcd() {
    var i2c = require('./lib/i2c');
    var display = new i2c.LCD(0);

    display.setColor(0, 60, 255);
    display.setCursor(1, 1);
    display.write('hi there');
    display.setCursor(0,0);  
    display.write('more text');
    display.waitForQuiescent()
    .then(function() {
        rotateColors(display);
    })
    .fail(function(err) {
        console.log(err);
        display.clearError();
        rotateColors(display);
    });
}
