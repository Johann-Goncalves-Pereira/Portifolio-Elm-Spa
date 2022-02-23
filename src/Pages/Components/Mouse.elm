module Pages.Components.Mouse exposing (..)

import Html exposing (Attribute)
import Html.Events exposing (custom)
import Html.Events.Extra.Mouse as EMouse
import Json.Decode as Decode exposing (Decoder)


type alias EventPeekOffsetPosition =
    { mouseEvent : EMouse.Event
    , movement : ( Float, Float )
    }


type alias EventPeekScreenPosition =
    { mouseEvent : EMouse.Event
    , movement : ( Float, Float )
    }


type alias Mouse =
    { mouseOffsetPosition : ( Float, Float )
    , mouseScreenPosition : ( Float, Float )
    }


init : Mouse
init =
    Mouse ( 0, 0 ) ( 0, 0 )


type MsgMouse
    = OffsetPosition ( Float, Float )
    | ScreenPosition ( Float, Float )


update : MsgMouse -> Mouse -> Mouse
update msg mouse =
    case msg of
        OffsetPosition ( x, y ) ->
            { mouse | mouseOffsetPosition = ( x, y ) }

        ScreenPosition ( x, y ) ->
            { mouse | mouseScreenPosition = ( x, y ) }



-- Decode Offset


decodeChangeOffsetPosition : Decoder EventPeekOffsetPosition
decodeChangeOffsetPosition =
    Decode.map2 EventPeekOffsetPosition
        EMouse.eventDecoder
        changeOffsetPositionDecoder


changeOffsetPositionDecoder : Decoder ( Float, Float )
changeOffsetPositionDecoder =
    Decode.map2 (\a b -> ( a, b ))
        (Decode.field "offsetX" Decode.float)
        (Decode.field "offsetY" Decode.float)


onChangeOffsetPosition : (MsgMouse -> msg) -> Attribute msg
onChangeOffsetPosition extMsg =
    let
        decoder =
            decodeChangeOffsetPosition
                |> Decode.map (.movement >> OffsetPosition >> extMsg)
                |> Decode.map options

        options message =
            { message = message
            , stopPropagation = False
            , preventDefault = True
            }
    in
    custom "mousemove" decoder



-- Decode Screen


decodeChangeScreenPosition : Decoder EventPeekScreenPosition
decodeChangeScreenPosition =
    Decode.map2 EventPeekScreenPosition
        EMouse.eventDecoder
        changeScreenPositionDecoder


changeScreenPositionDecoder : Decoder ( Float, Float )
changeScreenPositionDecoder =
    Decode.map2 (\a b -> ( a, b ))
        (Decode.field "offsetX" Decode.float)
        (Decode.field "offsetY" Decode.float)


onChangeScreenPosition : (MsgMouse -> msg) -> Attribute msg
onChangeScreenPosition extMsg =
    let
        decoder =
            decodeChangeScreenPosition
                |> Decode.map (.movement >> OffsetPosition >> extMsg)
                |> Decode.map options

        options message =
            { message = message
            , stopPropagation = False
            , preventDefault = True
            }
    in
    custom "mousemove" decoder


xPos : Mouse -> Float
xPos model =
    Tuple.first model.mouseOffsetPosition


yPos : Mouse -> Float
yPos model =
    Tuple.second model.mouseOffsetPosition