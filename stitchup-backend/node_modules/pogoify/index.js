var pogo = require('pogo');
var fs = require('fs');
var through = require('through');
var convert = require('convert-source-map');

function compile(file, data) {
    var compiled = '';
    try {
        compiled = pogo.compile(fs.readFileSync(file, 'utf8'));
    }
    catch (e) {
        throw new Error("PogoScript compilation failed for '" + file + "'\n" + e.toString())
    }
    return compiled;
}

function isPogo (file) {
    return /\.pogo$/.test(file);
}

module.exports = function (file) {
    if (!isPogo(file)) return through();

    var data = '';
    return through(write, end);

    function write (buf) { data += buf }
    function end () {
        var src;
        try {
            src = compile(file, data);
        } catch (error) {
            this.emit('error', error);
        }
        this.queue(src);
        this.queue(null);
    }
};
