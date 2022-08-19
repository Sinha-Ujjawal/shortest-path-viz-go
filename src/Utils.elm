module Utils exposing (..)


cartesianProduct : List a -> List b -> List ( a, b )
cartesianProduct aitems bitems =
    aitems
        |> List.concatMap (\a -> List.map (\b -> ( a, b )) bitems)
