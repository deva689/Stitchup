'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

exports.default = function (str) {
  var prefix = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : '_';

  var val = 5381;
  var i = str.length;

  while (i) {
    val = val * 33 ^ str.charCodeAt(--i);
  }

  return prefix + (val >>> 0).toString(36);
};