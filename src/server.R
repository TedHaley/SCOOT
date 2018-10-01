
# API keys
mapbox_access_key <- "KEY"
translink_key <- "KEY"
google_key <- "KEY"

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

shinyServer(function(input, output, session) {
  
  # Basic map 
  output$map <- renderLeaflet({
    leaflet() %>% 
      addProviderTiles(providers$CartoDB.Positron) %>% 
      setView(lng=-100, lat=40, zoom=3 ) 
  })

  # Enter button for text
  addressText <- eventReactive(input$goButton, {
    input$endAddress
  })
  
  # Find geolocalisation coordinates when user clicks
  observeEvent(input$geoloc, {
    js$geoloc()
  })
  
  # Only user location is known. Zoom into their location.
  observe({
    if (!is.null(input$lat) & input$endAddress == ""){
      
      dist <- 0.005
      lat_start <- input$lat
      lng_start <- input$long
        
      leafletProxy(mapId = "map") %>%
        fitBounds(lng_start - dist, lat_start - dist, lng_start + dist, lat_start + dist) %>% 
        addAwesomeMarkers(lng = lng_start, 
                          lat = lat_start, 
                          layerId = "start_maker",
                          popup = paste("<b>Your Location</b>", "<br>",
                                        "<b>Longitude:</b>", lng_start, "<br>",
                                        "<b>Latitude:</b>", lat_start), 
                          icon = makeAwesomeIcon(library = "fa",
                                                 icon = "circle",
                                                 markerColor = "green"))
      } 
  })
  
  # Only the end location is known. Zoom into the end address.
  observe({
    if (is.null(input$lat) & input$endAddress != ""){

      dest_address <- google_geocode(address = addressText(), key = google_key)
      address_end <- dest_address$results$formatted_address[1]
      lat_end <- dest_address$results$geometry$location$lat[1]
      lng_end <- dest_address$results$geometry$location$lng[1]

      dist <- 0.005

      leafletProxy(mapId = "map") %>%
        clearShapes() %>%
        clearMarkers() %>% 
        fitBounds(lng_end - dist, lat_end - dist, lng_end + dist, lat_end + dist) %>%
        addAwesomeMarkers(lng = lng_end,
                          lat = lat_end,
                          layerId = "end_marker",
                          popup = paste0("<b>",input$endAddress,"</b><br>",
                                         address_end),
                          icon = makeAwesomeIcon(library = "fa",
                                                 icon = "circle",
                                                 markerColor = "red"))
    }
  })
  
  # Both start and end points are known. We can plot between the two locations
  observe({
    if (!is.null(input$lat) & input$endAddress != ""){

      # Start details
      lat_start <- input$lat
      lng_start <- input$long
      
      origin <- c(lat_start, lng_start)
      destination <- addressText()
      
      mode <- input$mode
      
      # End details
      dest_address <- google_geocode(address = addressText(), key = google_key)
      address_end <- dest_address$results$formatted_address[1]
      lat_end <- dest_address$results$geometry$location$lat[1]
      lng_end <- dest_address$results$geometry$location$lng[1]

      # Get directions using Google Maps API
      res <- google_directions(origin = origin,
                               destination = c(lat_end, lng_end),
                               key = google_key,
                               mode = mode)

      steps <- direction_steps(res)
      
      # Warning when there are no directions
      if (is.null(steps)){
        
        showNotification(paste0("No ",mode," directions available between your location and ", address_end), 
                         duration = 10,
                         type = "message")
        
      # Print directions when available  
      }else{
        
        # lat/long fit to screen
        dist <- 0.005
        lat_diff <- abs(lat_start - lat_end) + dist
        lng_diff <- abs(lng_start - lng_end) + dist
        lat_mean <- (lat_start + lat_end) / 2
        lng_mean <- (lng_start + lng_end) / 2
        
        # Base map
        map <- leafletProxy(mapId = "map") %>%
          addProviderTiles(providers$CartoDB.Positron) %>%
          fitBounds(lng_mean - lng_diff, lat_mean - lat_diff, lng_mean + lng_diff, lat_mean + lat_diff) %>%
          clearShapes() %>% 
          clearMarkers()
        
        # Add markers with instructions
        for (step in 1:length(steps$html_instructions)){
          
          df_polyline <- decode_pl(steps$polyline[1]$points[step])
          
          # If Transit is selected
          if (steps$travel_mode[step] == "TRANSIT"){
            lat_stop <- steps$transit_details$departure_stop$location$lat[step]
            long_stop <- steps$transit_details$departure_stop$location$lng[step]
            
            # Finds the closest stop to the transit stop direction from Google
            static_stops_df <- static_stops(latitude = lat_stop, longitude = long_stop, translink_key = translink_key)
            
            # If there are no close Translink stops, give default directions
            if (is.null(static_stops_df)){
              
              # Add translink bus time to map
              map <- map %>%
                addCircleMarkers(lng = steps$start_location$lng[step], 
                                 lat = steps$start_location$lat[step], 
                                 popup = paste0(steps$html_instructions[step]))
              
            # The user is not within translink bounds
            }else{
              
              closest_stop_df <- head(static_stops_df,1)
              live_stops_df <- live_stops(static_stops_df = closest_stop_df, translink_key = translink_key) %>%
                mutate_if(is.factor, as.character) %>%
                filter(route_num == paste0(steps$transit_details$line$short_name[step]," "))
              
              # Add translink bus time to map
              map <- map %>%
                addCircleMarkers(lng = steps$start_location$lng[step], 
                                 lat = steps$start_location$lat[step], 
                                 popup = paste0(steps$html_instructions[step],"<br>",
                                                "Next ",steps$transit_details$line$short_name[step] ," Bus: ", live_stops_df$leave_time[1]))
            }
            
            
            
            # Add all other directions to the map
          } else{
            map <- map %>%
              addCircleMarkers(lng = steps$start_location$lng[step], 
                               lat = steps$start_location$lat[step], 
                               popup = steps$html_instructions[step])
          }
          
          
          # Add the direction line
          map <- map %>% 
            addPolylines(data = df_polyline, 
                         lat = ~lat, 
                         lng = ~lon, 
                         popup = paste0(steps$travel_mode[step],"<br>Duration: ",steps$duration$text[step]),
                         color = ifelse(steps$travel_mode[step]=="WALKING", yes = "green", 
                                        no = ifelse(steps$travel_mode[step]=="BICYCLING", yes = "blue", 
                                                    no = ifelse(steps$travel_mode[step]=="TRANSIT", yes = "orange", 
                                                                no = "red"))))
        }
        
        # Add end point
        map <- map %>%
          addAwesomeMarkers(lng = lng_end,
                            lat = lat_end,
                            layerId = "end_marker",
                            popup = paste0("<b>",input$endAddress,"</b><br>",
                                           address_end),
                            icon = makeAwesomeIcon(library = "fa",
                                                   icon = "circle",
                                                   markerColor = "red"))
        
        # Add start point
        map <- map %>%
          addAwesomeMarkers(lng = lng_start,
                            lat = lat_start,
                            popup = paste("<b>Your Location</b>", "<br>",
                                          "<b>Longitude:</b>", lng_start, "<br>",
                                          "<b>Latitude:</b>", lat_start), 
                            icon = makeAwesomeIcon(library = "fa",
                                                   icon = "circle",
                                                   markerColor = "green"))
        
        map
        
      }

    }
  })
})