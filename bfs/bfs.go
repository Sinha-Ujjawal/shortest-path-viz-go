package bfs

type bfsParent[T comparable] struct {
	parent T
	isEnd  bool
}

func BFS[T comparable](start, end T, neighborFn func(T) map[T]bool) map[T]bfsParent[T] {
	parentMap := map[T]bfsParent[T]{}
	parentMap[start] = bfsParent[T]{isEnd: true}
	frontier := map[T]bool{}
	frontier[start] = true
	for {
		// No more nodes to explore
		if len(frontier) == 0 {
			break
		}
		// End was already explored (-- early stopping)
		if _, ok := frontier[end]; ok {
			break
		}

		newFrontier := map[T]bool{}

		for u := range frontier {
			for v := range neighborFn(u) {
				if _, ok := parentMap[v]; ok {
					continue
				}
				parentMap[v] = bfsParent[T]{parent: u, isEnd: false}
				newFrontier[v] = true
			}
		}

		frontier = newFrontier
	}
	return parentMap
}

func ShortestPath[T comparable](start, end T, neighborFn func(T) map[T]bool) []T {
	parentMap := BFS(start, end, neighborFn)
	var ret []T
	curr := end

	for {
		if parentOfCurr, ok := parentMap[curr]; ok {
			ret = append(ret, curr)
			if parentOfCurr.isEnd {
				break
			}
			curr = parentOfCurr.parent
		} else {
			break
		}
	}

	for i, j := 0, len(ret)-1; i < j; i, j = i+1, j-1 {
		ret[i], ret[j] = ret[j], ret[i]
	}

	return ret
}
