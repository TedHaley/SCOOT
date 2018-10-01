# Queries new bus locations when called.
live_buses <- function(translink_key = translink_key){
  
  # Get all the buses in Vancouver
  all_buses <- 'http://api.translink.ca/rttiapi/v1/buses?apikey='
  
  # Translink is XML
  livebus <- GET(paste0(all_buses,translink_key))
  buses_xml <- content(livebus, type = "text", encoding = "UTF-8")
  buses_xml_parsed <- xmlParse(buses_xml)
  buses_df <- xmlToDataFrame(buses_xml_parsed)
  
  # Convert columns to numeric so they can be put on the map
  buses_df$Latitude <- as.numeric(buses_df$Latitude)
  buses_df$Longitude <- as.numeric(buses_df$Longitude)
  
  return(buses_df)
}
