let buildArgsList;

// `modulePromise` is a promise to the `WebAssembly.module` object to be
//   instantiated.
// `importObjectPromise` is a promise to an object that contains any additional
//   imports needed by the module that aren't provided by the standard runtime.
//   The fields on this object will be merged into the importObject with which
//   the module will be instantiated.
// This function returns a promise to the instantiated module.
export const instantiate = async (modulePromise, importObjectPromise) => {
    let dartInstance;

    function stringFromDartString(string) {
        const totalLength = dartInstance.exports.$stringLength(string);
        let result = '';
        let index = 0;
        while (index < totalLength) {
          let chunkLength = Math.min(totalLength - index, 0xFFFF);
          const array = new Array(chunkLength);
          for (let i = 0; i < chunkLength; i++) {
              array[i] = dartInstance.exports.$stringRead(string, index++);
          }
          result += String.fromCharCode(...array);
        }
        return result;
    }

    function stringToDartString(string) {
        const length = string.length;
        let range = 0;
        for (let i = 0; i < length; i++) {
            range |= string.codePointAt(i);
        }
        if (range < 256) {
            const dartString = dartInstance.exports.$stringAllocate1(length);
            for (let i = 0; i < length; i++) {
                dartInstance.exports.$stringWrite1(dartString, i, string.codePointAt(i));
            }
            return dartString;
        } else {
            const dartString = dartInstance.exports.$stringAllocate2(length);
            for (let i = 0; i < length; i++) {
                dartInstance.exports.$stringWrite2(dartString, i, string.charCodeAt(i));
            }
            return dartString;
        }
    }

    // Prints to the console
    function printToConsole(value) {
      if (typeof dartPrint == "function") {
        dartPrint(value);
        return;
      }
      if (typeof console == "object" && typeof console.log != "undefined") {
        console.log(value);
        return;
      }
      if (typeof print == "function") {
        print(value);
        return;
      }

      throw "Unable to print message: " + js;
    }

    // Converts a Dart List to a JS array. Any Dart objects will be converted, but
    // this will be cheap for JSValues.
    function arrayFromDartList(constructor, list) {
        const length = dartInstance.exports.$listLength(list);
        const array = new constructor(length);
        for (let i = 0; i < length; i++) {
            array[i] = dartInstance.exports.$listRead(list, i);
        }
        return array;
    }

    buildArgsList = function(list) {
        const dartList = dartInstance.exports.$makeStringList();
        for (let i = 0; i < list.length; i++) {
            dartInstance.exports.$listAdd(dartList, stringToDartString(list[i]));
        }
        return dartList;
    }

    // A special symbol attached to functions that wrap Dart functions.
    const jsWrappedDartFunctionSymbol = Symbol("JSWrappedDartFunction");

    function finalizeWrapper(dartFunction, wrapped) {
        wrapped.dartFunction = dartFunction;
        wrapped[jsWrappedDartFunctionSymbol] = true;
        return wrapped;
    }

    // Imports
    const dart2wasm = {

_45: (decoder, codeUnits) => decoder.decode(codeUnits),
_46: () => new TextDecoder("utf-8", {fatal: true}),
_47: () => new TextDecoder("utf-8", {fatal: false}),
_48: x0 => globalThis.mrtJsHandler = x0,
_49: x0 => globalThis.mrtWalletActivation = x0,
_50: f => finalizeWrapper(f,x0 => dartInstance.exports._50(f,x0)),
_51: f => finalizeWrapper(f,() => dartInstance.exports._51(f)),
_52: v => stringToDartString(v.toString()),
_63: Date.now,
_65: s => new Date(s * 1000).getTimezoneOffset() * 60 ,
_66: s => {
      const jsSource = stringFromDartString(s);
      if (!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(jsSource)) {
        return NaN;
      }
      return parseFloat(jsSource);
    },
_67: () => {
          let stackString = new Error().stack.toString();
          let frames = stackString.split('\n');
          let drop = 2;
          if (frames[0] === 'Error') {
              drop += 1;
          }
          return frames.slice(drop).join('\n');
        },
_76: s => stringToDartString(JSON.stringify(stringFromDartString(s))),
_77: s => printToConsole(stringFromDartString(s)),
_95: (c) =>
              queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
_97: (a, i) => a.push(i),
_104: (a, s) => a.join(s),
_105: (a, s, e) => a.slice(s, e),
_108: a => a.length,
_110: (a, i) => a[i],
_111: (a, i, v) => a[i] = v,
_113: a => a.join(''),
_114: (o, a, b) => o.replace(a, b),
_116: (s, t) => s.split(t),
_117: s => s.toLowerCase(),
_119: s => s.trim(),
_122: (s, n) => s.repeat(n),
_123: (s, p, i) => s.indexOf(p, i),
_124: (s, p, i) => s.lastIndexOf(p, i),
_125: (o, offsetInBytes, lengthInBytes) => {
      var dst = new ArrayBuffer(lengthInBytes);
      new Uint8Array(dst).set(new Uint8Array(o, offsetInBytes, lengthInBytes));
      return new DataView(dst);
    },
_126: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
_127: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
_128: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
_129: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
_130: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
_131: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
_132: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
_135: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
_136: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
_137: Object.is,
_140: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
_142: o => o.buffer,
_143: o => o.byteOffset,
_144: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
_145: (b, o) => new DataView(b, o),
_146: (b, o, l) => new DataView(b, o, l),
_147: Function.prototype.call.bind(DataView.prototype.getUint8),
_148: Function.prototype.call.bind(DataView.prototype.setUint8),
_149: Function.prototype.call.bind(DataView.prototype.getInt8),
_150: Function.prototype.call.bind(DataView.prototype.setInt8),
_151: Function.prototype.call.bind(DataView.prototype.getUint16),
_152: Function.prototype.call.bind(DataView.prototype.setUint16),
_153: Function.prototype.call.bind(DataView.prototype.getInt16),
_154: Function.prototype.call.bind(DataView.prototype.setInt16),
_155: Function.prototype.call.bind(DataView.prototype.getUint32),
_156: Function.prototype.call.bind(DataView.prototype.setUint32),
_157: Function.prototype.call.bind(DataView.prototype.getInt32),
_158: Function.prototype.call.bind(DataView.prototype.setInt32),
_163: Function.prototype.call.bind(DataView.prototype.getFloat32),
_165: Function.prototype.call.bind(DataView.prototype.getFloat64),
_167: (x0,x1) => x0.getRandomValues(x1),
_168: x0 => new Uint8Array(x0),
_169: () => globalThis.crypto,
_173: s => stringToDartString(stringFromDartString(s).toLowerCase()),
_175: (s, m) => {
          try {
            return new RegExp(s, m);
          } catch (e) {
            return String(e);
          }
        },
_176: (x0,x1) => x0.exec(x1),
_178: (x0,x1) => x0.exec(x1),
_186: o => o === undefined,
_187: o => typeof o === 'boolean',
_188: o => typeof o === 'number',
_190: o => typeof o === 'string',
_193: o => o instanceof Int8Array,
_194: o => o instanceof Uint8Array,
_195: o => o instanceof Uint8ClampedArray,
_196: o => o instanceof Int16Array,
_197: o => o instanceof Uint16Array,
_198: o => o instanceof Int32Array,
_199: o => o instanceof Uint32Array,
_200: o => o instanceof Float32Array,
_201: o => o instanceof Float64Array,
_202: o => o instanceof ArrayBuffer,
_203: o => o instanceof DataView,
_204: o => o instanceof Array,
_205: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
_208: o => o instanceof RegExp,
_209: (l, r) => l === r,
_210: o => o,
_211: o => o,
_212: o => o,
_213: b => !!b,
_214: o => o.length,
_217: (o, i) => o[i],
_218: f => f.dartFunction,
_219: l => arrayFromDartList(Int8Array, l),
_220: l => arrayFromDartList(Uint8Array, l),
_221: l => arrayFromDartList(Uint8ClampedArray, l),
_222: l => arrayFromDartList(Int16Array, l),
_223: l => arrayFromDartList(Uint16Array, l),
_224: l => arrayFromDartList(Int32Array, l),
_225: l => arrayFromDartList(Uint32Array, l),
_226: l => arrayFromDartList(Float32Array, l),
_227: l => arrayFromDartList(Float64Array, l),
_228: (data, length) => {
          const view = new DataView(new ArrayBuffer(length));
          for (let i = 0; i < length; i++) {
              view.setUint8(i, dartInstance.exports.$byteDataGetUint8(data, i));
          }
          return view;
        },
_229: l => arrayFromDartList(Array, l),
_230: stringFromDartString,
_231: stringToDartString,
_234: l => new Array(l),
_238: (o, p) => o[p],
_242: o => String(o),
_247: x0 => x0.index,
_249: x0 => x0.length,
_251: (x0,x1) => x0[x1],
_255: x0 => x0.flags,
_256: x0 => x0.multiline,
_257: x0 => x0.ignoreCase,
_258: x0 => x0.unicode,
_259: x0 => x0.dotAll,
_260: (x0,x1) => x0.lastIndex = x1
    };

    const baseImports = {
        dart2wasm: dart2wasm,


        Math: Math,
        Date: Date,
        Object: Object,
        Array: Array,
        Reflect: Reflect,
    };

    const jsStringPolyfill = {
        "charCodeAt": (s, i) => s.charCodeAt(i),
        "compare": (s1, s2) => {
            if (s1 < s2) return -1;
            if (s1 > s2) return 1;
            return 0;
        },
        "concat": (s1, s2) => s1 + s2,
        "equals": (s1, s2) => s1 === s2,
        "fromCharCode": (i) => String.fromCharCode(i),
        "length": (s) => s.length,
        "substring": (s, a, b) => s.substring(a, b),
    };

    dartInstance = await WebAssembly.instantiate(await modulePromise, {
        ...baseImports,
        ...(await importObjectPromise),
        "wasm:js-string": jsStringPolyfill,
    });

    return dartInstance;
}

// Call the main function for the instantiated module
// `moduleInstance` is the instantiated dart2wasm module
// `args` are any arguments that should be passed into the main function.
export const invoke = (moduleInstance, ...args) => {
    const dartMain = moduleInstance.exports.$getMain();
    const dartArgs = buildArgsList(args);
    moduleInstance.exports.$invokeMain(dartMain, dartArgs);
}

