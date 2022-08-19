port module Main exposing (main)

import Array exposing (Array)
import Browser
import Css
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attrs
import Html.Styled.Events as Events
import MyCss
import Set exposing (Set)
import Utils


minWidth : Int
minWidth =
    10


maxWidth : Int
maxWidth =
    50


minHeight : Int
minHeight =
    10


maxHeight : Int
maxHeight =
    50


type SybmolType
    = Start
    | End
    | Obstacle


symbolTypeToString : SybmolType -> String
symbolTypeToString cb =
    case cb of
        Start ->
            "🟢"

        End ->
            "🔴"

        Obstacle ->
            "🚧"


type ClickButtonType
    = ST SybmolType
    | Delete


type alias Model =
    { start : Maybe ( Int, Int )
    , end : Maybe ( Int, Int )
    , obstacles : Set ( Int, Int )
    , path : Set ( Int, Int )
    , clickButtonType : ClickButtonType
    , width : Int
    , height : Int
    , allowDiagonal : Bool
    , disableInput : Bool
    }


type alias BFSRequest =
    { start : ( Int, Int )
    , end : ( Int, Int )
    , obstacles : Array ( Int, Int )
    , width : Int
    , height : Int
    , allowDiagonal : Bool
    }


port requestForBFS : BFSRequest -> Cmd msg


port subscribeForBFSPath : (Array ( Int, Int ) -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions _ =
    subscribeForBFSPath SetPath


type Msg
    = NoOp
    | SwitchClickButtonType ClickButtonType
    | ApplyClickButtonTypeOnCell ( Int, Int )
    | ComputePath
    | Reset
    | SetWidth Int
    | SetHeight Int
    | ToogleDiagonal
    | SetPath (Array ( Int, Int ))


initModel : Int -> Int -> () -> ( Model, Cmd Msg )
initModel width height _ =
    ( { start = Nothing
      , end = Nothing
      , obstacles = Set.empty
      , path = Set.empty
      , clickButtonType = ST Start
      , width = width
      , height = height
      , allowDiagonal = False
      , disableInput = False
      }
    , Cmd.none
    )


emptyCell : List (Html.Attribute msg) -> Html msg
emptyCell attrs =
    MyCss.styledNode attrs []


startCell : List (Html.Attribute msg) -> Html msg
startCell attrs =
    MyCss.styledNode attrs [ Html.text (symbolTypeToString Start) ]


endCell : List (Html.Attribute msg) -> Html msg
endCell attrs =
    MyCss.styledNode attrs [ Html.text (symbolTypeToString End) ]


obstacleCell : List (Html.Attribute msg) -> Html msg
obstacleCell attrs =
    MyCss.styledNode attrs [ Html.text (symbolTypeToString Obstacle) ]


pathCell : List (Html.Attribute msg) -> Html msg
pathCell attrs =
    MyCss.withBackgroundBlack MyCss.styledNode attrs []


drawGrid : Bool -> Model -> Html Msg
drawGrid isDisabled model =
    let
        rowIds =
            List.range 1 model.height

        colIds =
            List.range 1 model.width

        renderCell ( rowId, colId ) =
            let
                cell =
                    if Just ( rowId, colId ) == model.start then
                        startCell

                    else if Just ( rowId, colId ) == model.end then
                        endCell

                    else if Set.member ( rowId, colId ) model.obstacles then
                        obstacleCell

                    else if Set.member ( rowId, colId ) model.path then
                        pathCell

                    else
                        emptyCell
            in
            cell
                (if isDisabled then
                    []

                 else
                    [ Events.onClick (ApplyClickButtonTypeOnCell ( rowId, colId )) ]
                )

        elements =
            Utils.cartesianProduct rowIds colIds
                |> List.map renderCell
    in
    MyCss.styledGrid model.width [] elements


drawButton : Bool -> String -> Msg -> Html Msg
drawButton isDisabled buttonText msg =
    Html.styled Html.button
        [ Css.margin (Css.px 10) ]
        [ Events.onClick msg, Attrs.disabled isDisabled ]
        [ Html.text buttonText ]


drawStartButton : Bool -> Html Msg
drawStartButton isDisabled =
    drawButton isDisabled (symbolTypeToString Start) (SwitchClickButtonType (ST Start))


drawEndButton : Bool -> Html Msg
drawEndButton isDisabled =
    drawButton isDisabled (symbolTypeToString End) (SwitchClickButtonType (ST End))


drawObstacleButton : Bool -> Html Msg
drawObstacleButton isDisabled =
    drawButton isDisabled (symbolTypeToString Obstacle) (SwitchClickButtonType (ST Obstacle))


drawDeleteButton : Bool -> Html Msg
drawDeleteButton isDisabled =
    drawButton isDisabled "x" (SwitchClickButtonType Delete)


printCurrentClickButtonTypeMessage : Model -> Html Msg
printCurrentClickButtonTypeMessage model =
    Html.div []
        [ Html.text
            (case model.clickButtonType of
                ST st ->
                    "Click on grid cell to put " ++ symbolTypeToString st

                Delete ->
                    "Click on grid cell to clear the symbol"
            )
        ]


slider : Bool -> String -> Int -> Int -> Int -> (Int -> msg) -> Html msg
slider isDisabled label labelValue min max mkEvent =
    Html.div []
        [ Html.div [] [ Html.text (label ++ ": " ++ String.fromInt labelValue) ]
        , Html.input
            [ Events.onInput (\x -> String.toInt x |> Maybe.withDefault 0 |> mkEvent)
            , Attrs.type_ "range"
            , Attrs.value (String.fromInt labelValue)
            , Attrs.min (String.fromInt min)
            , Attrs.max (String.fromInt max)
            , Attrs.disabled isDisabled
            ]
            []
        ]


checkBox : Bool -> String -> Bool -> msg -> Html msg
checkBox isDisabled label isChecked event =
    Html.div []
        [ Html.div [] [ Html.text label ]
        , Html.input
            [ Events.onInput (\_ -> event)
            , Attrs.type_ "checkbox"
            , Attrs.checked isChecked
            , Attrs.disabled isDisabled
            ]
            []
        ]


view : Model -> Html Msg
view model =
    Html.styled Html.div
        [ Css.padding (Css.px 10) ]
        []
        [ drawGrid model.disableInput model
        , Html.styled Html.div
            [ Css.padding (Css.px 10) ]
            []
            [ drawStartButton model.disableInput
            , drawEndButton model.disableInput
            , drawObstacleButton model.disableInput
            , drawDeleteButton model.disableInput
            ]
        , printCurrentClickButtonTypeMessage model
        , Html.div [] [ drawButton model.disableInput "Compute Path" ComputePath ]
        , Html.div [] [ drawButton model.disableInput "Reset" Reset ]
        , slider model.disableInput "Width" model.width minWidth maxWidth SetWidth
        , slider model.disableInput "Height" model.height minHeight maxHeight SetHeight
        , checkBox model.disableInput "Allow Diagonal" model.allowDiagonal ToogleDiagonal
        ]


symbolTypeAtPosition : Model -> ( Int, Int ) -> Maybe SybmolType
symbolTypeAtPosition model ( rowId, colId ) =
    if Just ( rowId, colId ) == model.start then
        Just Start

    else if Just ( rowId, colId ) == model.end then
        Just End

    else if Set.member ( rowId, colId ) model.obstacles then
        Just Obstacle

    else
        Nothing


applyClickButtonTypeOnCell : ( Int, Int ) -> Model -> Model
applyClickButtonTypeOnCell ( rowId, colId ) model =
    let
        modelWithButtonApplied =
            case symbolTypeAtPosition model ( rowId, colId ) of
                Just st ->
                    case model.clickButtonType of
                        Delete ->
                            case st of
                                Start ->
                                    { model | start = Nothing }

                                End ->
                                    { model | end = Nothing }

                                Obstacle ->
                                    { model | obstacles = Set.remove ( rowId, colId ) model.obstacles }

                        _ ->
                            model

                Nothing ->
                    case model.clickButtonType of
                        ST Start ->
                            { model | start = Just ( rowId, colId ) }

                        ST End ->
                            { model | end = Just ( rowId, colId ) }

                        ST Obstacle ->
                            { model | obstacles = Set.insert ( rowId, colId ) model.obstacles }

                        _ ->
                            model
    in
    { modelWithButtonApplied | path = Set.empty }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        Reset ->
            initModel model.width model.height ()

        SwitchClickButtonType buttonType ->
            ( { model | clickButtonType = buttonType }, Cmd.none )

        ApplyClickButtonTypeOnCell pos ->
            ( applyClickButtonTypeOnCell pos model, Cmd.none )

        ComputePath ->
            case ( model.start, model.end ) of
                ( Just start, Just end ) ->
                    ( { model | disableInput = True }
                    , requestForBFS
                        { width = model.width
                        , height = model.height
                        , start = start
                        , end = end
                        , obstacles = model.obstacles |> Set.toList |> Array.fromList
                        , allowDiagonal = model.allowDiagonal
                        }
                    )

                _ ->
                    ( model, Cmd.none )

        SetWidth width ->
            ( { model | width = width, path = Set.empty }, Cmd.none )

        SetHeight height ->
            ( { model | height = height, path = Set.empty }, Cmd.none )

        ToogleDiagonal ->
            ( { model | allowDiagonal = not model.allowDiagonal, path = Set.empty }, Cmd.none )

        SetPath path ->
            ( { model | disableInput = False, path = path |> Array.toList |> Set.fromList }, Cmd.none )


main : Program () Model Msg
main =
    Browser.element
        { view = view >> Html.toUnstyled
        , update = update
        , init = initModel minWidth minHeight
        , subscriptions = subscriptions
        }
