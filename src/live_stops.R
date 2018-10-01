# Gets the estimated arrival times for the bus stops listed
live_stops <- function(static_stops_df, translink_key = translink_key){
  
  datalist <- list()
  a <- 1
  
  for (StopNo in static_stops_df$StopNo){
    
    stop_estimate <- GET(paste0('http://api.translink.ca/rttiapi/v1/stops/',StopNo,'/estimates?apikey=',translink_key,'&count=1&timeframe=600'))
    stops_xml <- content(stop_estimate, type = "text", encoding = "UTF-8")
    stops_xml_parsed <- xmlParse(stops_xml)
    
    # Set the root and and count the number of route serviced at stop
    root <- xmlRoot(stops_xml_parsed)
    num_routes <- xmlSize(root)
    
    for (i in 1:num_routes){
      
      # Number of buses on this route
      num_buses_route <- xmlSize(root[[i]][["Schedules"]])
      
      for (n in 1:num_buses_route){
        
        # Add items to be saved
        stop_no <- StopNo
        route_num <- do.call(paste, as.list(capture.output(root[[i]][["RouteNo"]][[1]])))
        destination <- do.call(paste, as.list(capture.output(root[[i]][["Schedules"]][[n]][["Destination"]][[1]])))
        direction <- do.call(paste, as.list(capture.output(root[[i]][["Direction"]][[1]])))
        leave_time <- do.call(paste, as.list(capture.output(root[[i]][["Schedules"]][[n]][["ExpectedLeaveTime"]][[1]])))
        Latitude <- static_stops_df %>% 
          filter(StopNo == stop_no) %>% 
          select(Latitude)
        Longitude <- static_stops_df %>% 
          filter(StopNo == stop_no) %>% 
          select(Longitude)
        
        data <- data.frame(stop_no, route_num, destination, direction, leave_time, Longitude, Latitude)
        datalist[[a]] <- data
        
        a = a + 1
        
      }
    }
  }
  
  live_stops_df <- do.call(rbind, datalist)
  
  live_stops_df$Longitude <- as.numeric(as.character(live_stops_df$Longitude))
  live_stops_df$Latitude <- as.numeric(as.character(live_stops_df$Latitude))
  
  return(live_stops_df)
  
}