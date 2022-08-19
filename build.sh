set -e

tinygo build -o bfs.wasm -target wasm ./bfs_main.go
./build_elm.sh src/Main.elm
