var add = require('./adder');
describe('checkthese', function(){
  it('one', function(){
    throw new Error('this test fails.. but we don not have should/expect available yet, so throwing error to simulate');
  });
  it('two', function(){
    console.log('running second test');
  });
  it('three', function(){});
  it('four', function(){});
  it('five', function(){});
  it('six', function(){});
  it('seven', function(){
    if (add(1,1) !== 2){
      throw new Error('this test should pass');
    }
  });
});
