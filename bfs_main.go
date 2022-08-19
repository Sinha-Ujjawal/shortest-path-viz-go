package main

import (
	"bfs_wasm/bfs"
	"errors"
	"log"
)

func main() {
}

var inputBuffer [5050]uint8
var outputBuffer [5050]uint8

//export getInputBuffer
func getInputBuffer() *uint8 {
	return &inputBuffer[0]
}

//export getOutputBuffer
func getOutputBuffer() *uint8 {
	return &outputBuffer[0]
}

//export add2int
func add2int(x, y int) int {
	return x + y
}

type position struct {
	y uint8
	x uint8
}

type parsedInput struct {
	width         uint8
	height        uint8
	start         position
	end           position
	obstacles     map[position]bool
	allowDiagonal bool
}

func parseInput(data []uint8) (*parsedInput, error) {
	if len(data) < 7 {
		return nil, errors.New("Passed array should have atleast length 7")
	}
	if len(data)%2 != 1 {
		return nil, errors.New("Passed array must have odd number of elements")
	}
	allowDiagonal, width, height := data[0] == 1, data[1], data[2]
	start := position{y: data[3], x: data[4]}
	end := position{y: data[5], x: data[6]}
	obstacles := map[position]bool{}
	for i := 7; i < len(data)-1; i += 2 {
		obstacles[position{y: data[i], x: data[i+1]}] = true
	}
	return &parsedInput{width, height, start, end, obstacles, allowDiagonal}, nil
}

//export shortestPath
func shortestPath(data []uint8) uint32 {
	input, err := parseInput(data)
	if err != nil {
		log.Fatal(err)
	}

	upDownLeftRightNeighbors := func(pos *position, ret *map[position]bool) {
		if pos.y > 1 {
			up := position{x: pos.x, y: pos.y - 1}
			if _, ok := input.obstacles[up]; ok {

			} else {
				(*ret)[up] = true
			}
		}
		if pos.y < input.height {
			down := position{x: pos.x, y: pos.y + 1}
			if _, ok := input.obstacles[down]; ok {

			} else {
				(*ret)[down] = true
			}
		}
		if pos.x > 1 {
			left := position{x: pos.x - 1, y: pos.y}
			if _, ok := input.obstacles[left]; ok {

			} else {
				(*ret)[left] = true
			}
		}
		if pos.x < input.width {
			right := position{x: pos.x + 1, y: pos.y}
			if _, ok := input.obstacles[right]; ok {

			} else {
				(*ret)[right] = true
			}
		}
	}

	diagonalNeighbors := func(pos *position, ret *map[position]bool) {
		if pos.y > 1 && pos.x > 1 {
			upperLeft := position{x: pos.x - 1, y: pos.y - 1}
			if _, ok := input.obstacles[upperLeft]; ok {

			} else {
				(*ret)[upperLeft] = true
			}
		}
		if pos.y > 1 && pos.x < input.width {
			upperRight := position{x: pos.x + 1, y: pos.y - 1}
			if _, ok := input.obstacles[upperRight]; ok {

			} else {
				(*ret)[upperRight] = true
			}
		}
		if pos.y < input.height && pos.x > 1 {
			belowLeft := position{x: pos.x - 1, y: pos.y + 1}
			if _, ok := input.obstacles[belowLeft]; ok {

			} else {
				(*ret)[belowLeft] = true
			}
		}
		if pos.y < input.height && pos.x < input.width {
			belowRight := position{x: pos.x + 1, y: pos.y + 1}
			if _, ok := input.obstacles[belowRight]; ok {

			} else {
				(*ret)[belowRight] = true
			}
		}
	}

	neighborFn := func(pos position) map[position]bool {
		ret := map[position]bool{}
		upDownLeftRightNeighbors(&pos, &ret)
		if input.allowDiagonal {
			diagonalNeighbors(&pos, &ret)
		}
		return ret
	}

	path := bfs.ShortestPath(input.start, input.end, neighborFn)
	for i, pos := range path {
		outputBuffer[i<<1] = pos.y
		outputBuffer[(i<<1)+1] = pos.x
	}
	return uint32(len(path)) * 2
}
