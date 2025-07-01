#!/usr/bin/env node

if (!process.argv[2]) {
  console.log('Must supply a path to the tests');
  return
}

var path       = require('path');
var launch     = require('../server/launch');
var testFolder = path.resolve(process.cwd(), process.argv[2]);
var port       = process.argv[3] || 8765;

launch(testFolder, {port: port});

