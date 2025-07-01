var socket;
var bufferedLog = [];
var emit;

function intercept(){
  var originalLog = console.log;
  console.log = function(){
    originalLog.apply(this, arguments);
    var args = Array.prototype.slice.call(arguments);
    if (emit) {
      emit(args);
    }
    else {
      bufferedLog.push(args);
    }
  };
}

function connect(options){
  return new Promise(function(success){
    if (!options.url) throw new Error('Options requires a url');
    if (!options.sourceName) throw new Error('Options requires a sourceName');
    var io = require('socket.io-client');
    socket = io(options.url);
    emit = function(args){
      socket.emit('log', {source: options.sourceName, args: args});
    }

    socket.on('connect', function(){
      while(bufferedLog.length > 0){
        var logEntry = bufferedLog.shift()
        emit(logEntry);
      }
      success();
    });
  });
};

module.exports = function logToSocket(options){
  intercept();
  connect(options);
}

module.exports.intercept = intercept;
module.exports.connect = connect;
