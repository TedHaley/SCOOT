# Queries bus locations closest to the longitude and latitude
static_stops <- function(longitude, latitude, radius = 500, translink_key = translink_key){
  
  longitude <- format(round(longitude, 6), nsmall = 6)
  latitude <- format(round(latitude, 6), nsmall = 6)
  
  close_stops <- GET(paste0('http://api.translink.ca/rttiapi/v1/stops?apikey=',translink_key,'&lat=',latitude,'&long=',longitude,'&radius=',radius))
  
  # If no buses found. Longitude and Latitude out of range
  if (close_stops$status != 200){
    return(NULL)
    
  }else{
    
    stops_xml <- content(close_stops, type = "text", encoding = "UTF-8")
    stops_xml_parsed <- xmlParse(stops_xml)
    stops_df <- xmlToDataFrame(stops_xml_parsed)
    
    stops_df$Longitude <- as.numeric(as.character(stops_df$Longitude))
    stops_df$Latitude <- as.numeric(as.character(stops_df$Latitude))
    
    return(stops_df)
  }
}

