//  -*- Mode: Javascript; -*-                                      
// 
//  new_ffi_test.js
// 
//  © Copyright IBM Corporation 2016.
//  LICENSE: MIT License (https://opensource.org/licenses/mit-license.html)
//  AUTHOR: Jamie A. Jennings

//
// npm install ffi
//

var debug = require("debug");

var ffi = require("ffi");
var ref = require('ref');
var Struct = require('ref-struct');

var DynamicLibrary = require('./node_modules/ffi/lib/dynamic_library')
  , ForeignFunction = require('./node_modules/ffi/lib/foreign_function')

var libm = new ffi.Library("libm", { "ceil": [ "double", [ "double" ] ] });
console.log(libm.ceil(3.5)); // 4
 
var current = new ffi.Library(null, { "atoi": [ "int32", [ "string" ] ] });
console.log(current.atoi("01234")); // 1234 

var TimeVal = Struct({
  'tv_sec': 'long',
  'tv_usec': 'long'
});
var TimeValPtr = ref.refType(TimeVal);

var lib = new ffi.Library(null, { 'gettimeofday': [ 'int', [ TimeValPtr, "pointer" ] ]});
var tv = new TimeVal();
lib.gettimeofday(tv.ref(), null);
console.log("Seconds since epoch: " + tv.tv_sec);


var MyCString = Struct({
  'len': 'uint32',
  'ptr': 'string'
});

var MyCStringArray = Struct({
    'len': 'uint32',
    'ptr': ref.refType(ref.refType(MyCString))
});

var MyCStringPtr = ref.refType(MyCString)

var RTLD_NOW = ffi.DynamicLibrary.FLAGS.RTLD_NOW;
var RTLD_GLOBAL = ffi.DynamicLibrary.FLAGS.RTLD_GLOBAL;
var mode = RTLD_NOW | RTLD_GLOBAL;

var Rosie = new DynamicLibrary('librosie.so' || null, mode);

var funcs = {'initialize': [ 'int', ['string']],
	     'testbyref': [ 'int', [MyCStringPtr] ],
	     'testbyvalue': [ 'int', [MyCString] ],
	     'testretstring': [ MyCString, [MyCStringPtr] ],
	     'testretarray': [ MyCStringArray, [MyCString] ] }

var lib;
Object.keys(funcs || {}).forEach(function (func) {
    debug('defining function', func)

    var fptr = Rosie.get(func)
      , info = funcs[func]

    if (fptr.isNull()) {
      throw new Error('Library: "' + libfile
        + '" returned NULL function pointer for "' + func + '"')
    }

    var resultType = info[0]
      , paramTypes = info[1]
      , fopts = info[2]
      , abi = fopts && fopts.abi
      , async = fopts && fopts.async
      , varargs = fopts && fopts.varargs

    if (varargs) {
      lib[func] = VariadicForeignFunction(fptr, resultType, paramTypes, abi)
    } else {
      var ff = ForeignFunction(fptr, resultType, paramTypes, abi)
      lib[func] = async ? ff.async : ff
    }
  })

var str = new MyCString
str.len = 7
str.ptr = "Hello, world"
console.log("str len=", str.len, " and ptr=", str.ptr)

var retval = lib.testbyref(str.ref())
console.log("testbyref retval=", retval)

var retval = lib.testbyvalue(str)
console.log("testbyvalue retval=", retval)

var retval = lib.testretstring(str.ref())
console.log("testretstring retval=", retval)

var retval = lib.testretarray(str)
console.log("testretarray retval=", retval)

var n = retval.len
console.log(n)
var p = retval.ptr
console.log(p)
for (i=0; i<n; i++) {
    var cstr = ref.alloc(MyCString)
    cstr_ptr = ref.get(p, (i*ref.sizeof.pointer), MyCStringPtr)
    console.log("cstr_ptr: ", cstr_ptr)
    cstr = cstr_ptr.deref()
    console.log(i, cstr, "len=", cstr.len, "and ptr=", cstr.ptr)
}
    


console.log("About to initialize Rosie")
var i = lib.initialize("adasdasdasadsdsd")
console.log(i)

