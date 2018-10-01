# Libraries to be used in both ui.R and server.R
library(tidyverse)
library(httr)
library(curl) # make the jsonlite suggested dependency explicit
library(jsonlite)
library(leaflet)
library(shiny)
library(XML)
library(geosphere)

# For the geolocate
library(shinyjs)
library(V8)

# For the Radiobuttons
library(shinyWidgets)

# For google directions
library(googleway)

# Custom Functions:
# live bus locations:
source("live_buses.R")

# Bus arrival times by stop:
source("live_stops.R")

# Bus top locations
source("static_stops.R")