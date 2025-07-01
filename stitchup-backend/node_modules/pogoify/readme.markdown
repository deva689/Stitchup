# pogoify

browserify v2 plugin for PogoScript

mix and match `.pogo` and `.js` files in the same project

[![build status](https://secure.travis-ci.org/featurist/pogoify.png)](http://travis-ci.org/featurist/pogoify)

# install

```sh
npm install pogoify
```

# usage

## command line

```sh
browserify -t pogoify --extension .pogo app.pogo > app.js
```

`-t pogoify` tells browserify to compile any `.pogo` file it finds.
`--extension .pogo` tells browserify to consider files with the `.pogo` extension.

You can also mix and match Pogoscript files with other languages supported by browserify.

## express

    npm install browserify-middleware
    
Then, in app.js:

```js
var browserify = require('browserify-middleware');
    
...
    
app.get('browserapp.js', browserify('./browser/app.js', {transform: ['pogoify'], extensions: ['.pogo']}));
```

# example files

given some files written in a mix of `js` and `pogo`:

foo.pogo, the _entry_ file:
```pogo
console.log(require './bar')
```

bar.js:
```js
module.exports = require('./baz')(5)
```

baz.pogo:
```pogo
module.exports (n) = n * 111
```

# license

MIT
