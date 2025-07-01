var http          = require('http');
var express       = require('express');
var socketIO      = require('socket.io');
var launchBrowser = require('firefox-launch');
var path          = require('path');
var fs            = require('fs-promise');
var retry         = require('trytryagain');
var expect        = require('chai').expect;
var browserify    = require('browserify-middleware');

describe('redirect console.log', function(){
  var tmp;
  beforeEach(function(done){
    require('tmp').dir(function(err, path){
      tmp = path;
      done();
    });
  });
  afterEach(function(){
    return fs.remove(tmp);
  });
  it('captures console.log from the browser', function(){
    this.timeout(500000);
    var app = express();
    var httpServer = http.createServer(app);
    var socketServer = socketIO(httpServer);

    app.get('/index.js', browserify(__dirname + '/testApp.js'));

    app.get('/', function(req, res){
      res.send('<html><script src="/index.js"></script></html>')
    });

    return new Promise(function(success){
      var clientConnected = false;
      var logs = []
      socketServer.on('connection', function(socket){
        clientConnected = true;
        socket.on('log', function(data){
          logs.push(data);
        });      
      });
      httpServer.listen(9999, function(){
        launchBrowser("http://localhost:9999");

        retry({timeout: 7000}, function(){
          expect(clientConnected).to.be.true;
          expect(logs).to.eql([
            { source: 'test-app', args: ['this happpened', 123, [456]]},
            { source: 'test-app', args: ['that happpened', {a: 'b', b: 123}]}
          ]);
        }).then(success);        
      });
    });
  });
});
