
# Geolocation adapted from https://github.com/AugustT/shiny_geolocation
# Geolocation Javascript code
jsCode <- '
shinyjs.geoloc = function() {
navigator.geolocation.getCurrentPosition(onSuccess, onError);
function onError (err) {
Shiny.onInputChange("geolocation", false);
}
function onSuccess (position) {
setTimeout(function () {
var coords = position.coords;
console.log(coords.latitude + ", " + coords.longitude);
Shiny.onInputChange("geolocation", true);
Shiny.onInputChange("lat", coords.latitude);
Shiny.onInputChange("long", coords.longitude);
}, 5)
}
};
'

shinyUI(
  bootstrapPage(
    
    # Fullscreen
    tags$style(type = "text/css", "html,
               body {width:100%;height:100%}"),
    
    # Warning message location
    tags$head(
      tags$style(
        HTML(".shiny-notification {
             position:fixed;
             top: calc(51%);
             left: calc(33%);
             right: calc(33%);
             }
             "
        )
      )
    ),

    # Tell shiny we will use some Javascript for geolocation
    useShinyjs(),
    extendShinyjs(text = jsCode),

    # Map output
    leafletOutput("map", width= "100%", height = "100%"),

    # Location button
    absolutePanel(top = 20, right = 322, width = 40, height = 40,
                  actionButton("geoloc", label = NULL, class="btn btn-primary", onClick="shinyjs.geoloc()", 
                               icon = icon(name ="location-arrow"))
    ),
    
    # End address
    absolutePanel(top = 20, right = 20, width = 300, height = 40,
                  textInput(inputId = "endAddress", label = NULL, value = NULL)
    ),
    
    # Enter address button
    absolutePanel(top = 20, right = 20, width = 35, height = 40,
                  actionButton("goButton", label = NULL, 
                               icon = icon(name ="arrow-right"), style="color: #FFF; background-color: #4fa32c")
    ),
    
    # Mode selection
    absolutePanel(top = 57, right = 120, width = 200, height = 50,
                  radioGroupButtons(inputId = "mode", 
                                     label = NULL,
                               choiceNames = list(
                                 icon(name ="male"),
                                 icon(name ="bicycle"),
                                 icon(name ="bus"),
                                 icon(name ="car")
                               ),
                               choiceValues = list(
                                 "walking", "bicycling", "transit", "driving"
                               ),
                               selected = "walking")
    ),
    
    absolutePanel(bottom = 20, right = 20, width = 150, height = 40,
                  img(src='logo.png', width = 150))
  )
)







