import { wasmBrowserInstantiate, go } from "./index.js";

const runWASM = async () => {
  // Get the importObject from the go instance.
  const importObject = go.importObject;
  // Instantiate our wasm module
  const module = await wasmBrowserInstantiate("./bfs.wasm", importObject);
  // Allow the wasm_exec go instance, bootstrap and execute our wasm module
  go.run(module.instance);
  useWasmModule(module.instance.exports);
};
runWASM();

const useWasmModule = (exports) => {
  const insertIntoInputBuffer = (arr) => {
    // Get the address of the writable memory.
    let addr = exports.getInputBuffer();
    let buffer = exports.memory.buffer;

    let mem = new Uint8Array(buffer, addr, arr.length);
    mem.set(arr);

    // Return the address we started at.
    return addr;
  };

  const readFromOutputBuffer = (size) => {
    // Get the address of the writable memory.
    let addr = exports.getOutputBuffer();
    let buffer = exports.memory.buffer;

    let mem = new Uint8Array(buffer, addr, size);
    return mem;
  };

  window.shortestPath = (
    width,
    height,
    start,
    end,
    obstacles,
    allowDiagonal
  ) => {
    let flattenedArray = [
      allowDiagonal ? 1 : 0,
      width,
      height,
      ...start,
      ...end,
    ];
    obstacles.forEach(([x, y]) => {
      flattenedArray.push(x);
      flattenedArray.push(y);
    });
    let addr = insertIntoInputBuffer(flattenedArray);
    let pathLength = exports.shortestPath(addr, flattenedArray.length);
    let ret = [];
    let arr = Array.from(readFromOutputBuffer(pathLength));
    for (var i = 0; i < arr.length - 1; i += 2) {
      ret.push([arr[i], arr[i + 1]]);
    }
    return ret;
  };
};
