module Pages.Home_ exposing (Model, Msg, page)

import Browser.Dom exposing (Viewport, getViewport, getViewportOf)
import Browser.Events as BrowserE
import DOM exposing (offsetWidth, target)
import Effect
import Gen.Params.Home_ exposing (Params)
import Gen.Route as Route exposing (Route)
import Html exposing (Attribute, Html, a, article, b, br, div, h1, h2, h3, img, main_, p, section, span, strong, text)
import Html.Attributes exposing (attribute, class, id, src, style)
import Html.Events exposing (on, onClick)
import Html.Events.Extra.Mouse as EMouse
import Json.Decode as Decode exposing (Decoder)
import Page exposing (Page)
import Preview.Kelpie.Kelpie as Kelpie exposing (view)
import Request exposing (Request)
import Round
import Shared exposing (subscriptions)
import Svg.Base as MSvg
import Task
import UI
import View exposing (View)


type alias EventWithMovement =
    { mouseEvent : EMouse.Event
    , movement : ( Float, Float )
    }


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.element
        { init = init
        , subscriptions = subscriptionSize
        , update = update
        , view = view
        }



-- INIT


type alias Model =
    { route : Route
    , scrollSample : Bool
    , sectionSize : ( Int, Int )
    , mousePosition : ( Float, Float )
    }


init : ( Model, Cmd Msg )
init =
    ( { route = Route.Home_
      , scrollSample = False
      , sectionSize = ( 0, 0 )
      , mousePosition = ( 0, 0 )
      }
      -- , Cmd.none
    , Task.perform GotViewPort getViewport
    )



-- UPDATE


type Msg
    = ShowSample
    | GotViewPort Viewport
    | GotNewSize ( Int, Int )
    | MouseMovement ( Float, Float )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ShowSample ->
            ( { model | scrollSample = not model.scrollSample }, Cmd.none )

        GotNewSize sSize ->
            ( { model
                | sectionSize =
                    sSize
              }
            , Cmd.none
            )

        GotViewPort viewport ->
            let
                sizeWidth =
                    truncate viewport.viewport.width

                sizeHeight =
                    truncate viewport.viewport.height
            in
            ( { model
                | sectionSize = ( sizeWidth, sizeHeight )
              }
            , Cmd.none
            )

        MouseMovement ( x, y ) ->
            ( { model | mousePosition = ( x, y ) }, Cmd.none )


decodeWithMovement : Decoder EventWithMovement
decodeWithMovement =
    Decode.map2 EventWithMovement
        EMouse.eventDecoder
        movementDecoder


movementDecoder : Decoder ( Float, Float )
movementDecoder =
    Decode.map2 (\a b -> ( a, b ))
        (Decode.field "offsetX" Decode.float)
        (Decode.field "offsetY" Decode.float)


onMove : (EventWithMovement -> msg) -> Html.Attribute msg
onMove tag =
    let
        decoder =
            decodeWithMovement
                |> Decode.map tag
                |> Decode.map options

        options message =
            { message = message
            , stopPropagation = False
            , preventDefault = True
            }
    in
    Html.Events.custom "mousemove" decoder



-- Subscription


subscriptionSize : Model -> Sub Msg
subscriptionSize _ =
    BrowserE.onResize (\w h -> GotNewSize ( w, h ))



-- VIEW


view : Model -> View Msg
view model =
    { title = "Johann - Home"
    , body =
        UI.layout model.route
            [ viewMainContent
            , viewOtherProjects model
            ]
    }



-- Main Content


viewMainContent : Html Msg
viewMainContent =
    article [ class "main-home" ]
        [ div [ class "main-home__container", attribute "transitionOne" "" ]
            [ h1 [ class "main-home__medium-title" ]
                [ text "Johann Gonçalves Pereira"
                ]
            , h2
                [ class "main-home__big-title" ]
                [ span [ class "main-home__big-title--no-break" ] [ text "Front-End " ]
                , text "Developer"
                ]
            , h2 [ class "main-home__big-title" ]
                [ text "UI Developer"
                ]
            ]
        ]



-- Projects Content


viewOtherProjects : Model -> Html Msg
viewOtherProjects model =
    div [ class "cards" ]
        [ h3
            [ class "cards__title" ]
            [ span [] [ text "Other" ]
            , span [] [ text "Projects" ]
            ]
        , div
            [ class "cards__container"
            ]
          <|
            viewProjects model
        ]


calcDeg : Model -> ( Float, Float )
calcDeg model =
    let
        windowSize : Float
        windowSize =
            toFloat <| Tuple.first model.sectionSize

        size : Float
        size =
            875 * windowSize / 1925



        -- 852 = 1925
        -- x = 730
        width : Float
        width =
            size / 2

        height : Float
        height =
            38 * 16 / 2

        mouseX =
            Tuple.first model.mousePosition

        mouseY =
            Tuple.second model.mousePosition

        posX : Float
        posX =
            mouseX - width

        posY : Float
        posY =
            (mouseY - height) * -1

        depthX : Float
        depthX =
            if posX * 10 / 250 < -10 then
                -10

            else if posX * 10 / 250 > 10 then
                10

            else
                posX * 10 / 250

        depthY : Float
        depthY =
            if posY * 10 / 250 < -10 then
                -10

            else if posY * 10 / 250 > 10 then
                10

            else
                posY * 10 / 250

        --! How to debug in elm
        -- _ =
        --     Debug.log "Depth" ( depthX, depthY )
    in
    if posX * posY < 0 then
        ( depthX * -1, depthY * -1 )

    else
        ( depthX, depthY )


transformCard : Model -> Html.Attribute Msg
transformCard model =
    let
        ( x, y ) =
            calcDeg model

        localRound z =
            Round.round 3 z
    in
    "perspective(1000px) rotateX("
        ++ localRound x
        ++ "deg) rotateY("
        ++ localRound y
        ++ "deg) rotate(0deg)"
        |> style "transform"


getWidthElement : Html.Attribute Float
getWidthElement =
    on "click" (target offsetWidth)


viewProjects : Model -> List (Html Msg)
viewProjects model =
    let
        container funcContent =
            div [ class <| "project" ] funcContent
    in
    [ container <| kelpie model
    , div [] <| blobsInfo model
    ]


boldText : String -> Html Msg
boldText word =
    strong [] [ text <| " " ++ word ]


kelpie : Model -> List (Html Msg)
kelpie model =
    let
        isOverflowHidden =
            if model.scrollSample == True then
                style "overflow" "auto"

            else
                style "overflow" "hidden"

        isSpanDisplayed =
            if model.scrollSample == True then
                style "transform" "scale(0)"

            else
                style "transform" "scale(1)"
    in
    [ section [ class "project__information" ]
        [ p []
            [ boldText "Kelpie"
            , text <|
                " was a personal project I did in my spare time. "
                    ++ "It helped me to understand the basics of"
            , boldText "Elm"
            , text <|
                ", but what this project gave me the most was "
                    ++ "the absurd advance I had learning"
            , boldText "Css/Scss."
            ]
        , br [] []
        , p []
            [ text <|
                "This was my first attempt to make a website by myself"
                    ++ ", not copying from a course or a teacher."
            ]
        , br [] []
        , p []
            [ text "The site is obviously based on "
            , a [] [ text "Unsplash" ]
            , text ". It's just a personal site not a comercial one."
            ]
        ]
    , section
        [ class "project__content"

        -- , onMove (.movement >> MouseMovement)
        ]
        [ List.concat
            [ [ span
                    [ class "project-sample-block"
                    , onClick ShowSample
                    , isSpanDisplayed
                    ]
                    [ span []
                        [ text "click to see the sample"
                        ]
                    ]
              ]
            , Kelpie.view
            ]
            |> div
                [ id "kelpie-container"
                , isOverflowHidden
                , transformCard model
                , onMove (.movement >> MouseMovement)
                ]
        ]
    ]


blobsInfo : Model -> List (Html Msg)
blobsInfo model =
    [ section [ class "blobs-info" ]
        -- List.repeat 4 <|
        [ div [ class "blobs-info__content" ]
            [ MSvg.rocket <| Just "icon"
            , div [ class "txt" ]
                [ strong [ class "txt__title" ] [ text "Get the design" ]
                , p [ class "txt__text" ]
                    [ text
                        """
                        The first thing that I usually do when starting a new project,
                        It's talk with the design about what I need to do, if I need to 
                        made the page based on a figma or framer pre build. 
                        """
                    , br [] []
                    , br [] []
                    , text "Maybe I need to need to make the design by myself."
                    ]
                ]
            , div [ class "number" ] [ b [] [ text "01" ] ]
            ]
        , div [ class "blobs-info__content" ]
            [ MSvg.code <| Just "icon"
            , div [ class "txt" ]
                [ strong [ class "txt__title" ] [ text "Start to Code" ]
                , p [ class "txt__text" ]
                    [ text
                        """
                        Then before making the design I start to code, if possible I
                        like to use the tools that I'm used to.
                        """
                    , br [] []
                    , br [] []
                    , text "Elm, Scss, Html, ReactNative"
                    ]
                ]
            , div [ class "number" ] [ b [] [ text "02" ] ]
            ]
        , div [ class "blobs-info__content" ]
            [ MSvg.lineS <| Just "icon"
            , div [ class "txt" ]
                [ strong [ class "txt__title" ] [ text "Bugs and updates" ]
                , p [ class "txt__text" ]
                    [ text
                        """
                        You always need to improve something on the code,
                        and fix some bugs.
                        """
                    , br [] []
                    , br [] []
                    , text "And I can make this with a team or just by myself."
                    ]
                ]
            , div [ class "number" ] [ b [] [ text "03" ] ]
            ]
        , div [ class "blobs-info__content" ]
            [ MSvg.infinite <| Just "icon"
            , div [ class "txt" ]
                [ strong [ class "txt__title" ] [ text "Never stops" ]
                , p [ class "txt__text" ]
                    [ text
                        """
                        Software never stops, just keeps growing and getting more better.
                        
                        """
                    ]
                ]
            , div [ class "number" ] [ b [] [ text "04" ] ]
            ]
        ]
    ]
