# global -----

library(shiny)

library(tidyverse)
library(janitor)
library(lubridate)

library(bslib)
library(plotly)
library(leaflet) # for maps
library(sf) # if using geometry

# load in data ----

## for tab 1: winter v summer
## See below (Thijmen start...)

## for tab 2: hospital admissions
join_ha_map <- read_csv("cleaned_data/join_ha_map.csv") %>% 
  filter(hb != "S92000003")
ha_demo <- read_csv("cleaned_data/ha_demo_clean.csv")

## for tab 3: bed occupancy
hospital_location_occupancy <- read_csv("cleaned_data/hospital_location_occupancy.csv")
occupancy_per_hb <- read_csv("cleaned_data/occupancy_per_hb.csv") %>% 
  mutate(quarter = zoo::as.yearqtr(quarter))

## for tab 4: delayed discharge
delayed <- clean_names(read_csv("cleaned_data/delayed.csv"))
map_means <- read_csv("cleaned_data/delayed_map_means.csv")

# lists for selectors ----

hbs_list <- c("Ayrshire and Arran" = "S08000015",
              "Borders" = "S08000016",
              "Dumfries and Galloway" = "S08000017",
              "Forth Valley" = "S08000019",
              "Grampian" = "S08000020",
              "Highland" = "S08000022",
              "Lothian" = "S08000024",
              "Orkney" = "S08000025",
              "Shetland" = "S08000026",
              "Western Isles" = "S08000028",
              "Fife" = "S08000029",
              "Tayside" = "S08000030",
              "Greater Glasgow and Clyde" = "S08000031",
              "Lanarkshire" = "S08000032",
              "All Scotland" = "S92000003")#,
              #"The Golden Jubilee National Hospital" = "SB0801") # used on both pages for now

# theme for plots ----

theme_penguin <- function(){
  
  theme(legend.position = "bottom",
        panel.background = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.minor.y = element_blank(),
        axis.text = element_text(size = 16),
        axis.title = element_text(size = 16),
        legend.title = element_text(size = 14),
        legend.text = element_text(size = 14),
        plot.title = element_text(size = 18)
  )
  
}

## colour palettes for plots ----

# set "All Scotland" to "blue4" and individual hbs to "darkviolet"
scot_hb_colours <- c("S92000003" = "blue4",
                    "S08000015" = "darkviolet",
                    "S08000016" = "darkviolet",
                    "S08000017"= "darkviolet",
                    "S08000019" = "darkviolet",
                    "S08000020" = "darkviolet",
                    "S08000022" = "darkviolet",
                    "S08000024" = "darkviolet",
                    "S08000025" = "darkviolet",
                    "S08000026" = "darkviolet",
                    "S08000028"= "darkviolet",
                    "S08000029" = "darkviolet",
                    "S08000030" = "darkviolet",
                    "S08000031" = "darkviolet",
                    "S08000032" = "darkviolet")

# scot_hb_colours <- c("S92000003" = "blue4",
#                      "S08000015" = "darkviolet")

# show 3 different ages
age_colours <- c("Under 5" = "greenyellow",
                 "5 - 64" = "springgreen",
                 "over 65" = "darkgreen"
)

# show summer v winter
season_colours <- c("summer" = "goldenrod1",
                    "winter" = "steelblue1")

## static plots ----

# Chiara: admissions heatmap for all of scotland
admissions_pal <- colorNumeric(
  palette = "RdYlGn",
  domain = join_ha_map$mean_adm)
  
admissions_heatmap <- join_ha_map %>% 
  filter(!is.na(mean_adm)) %>% 
  leaflet(options = leafletOptions(zoomSnap = 0.2, zoomDelta=0.2)) %>% 
  addProviderTiles(providers$Stamen.TonerLite) %>%
  setView(-3.524194, 57.786499, zoom = 5.6) %>% 
  addCircleMarkers(lng = ~ longitude,
                   lat = ~ latitude,
                   weight = 0,
                   radius = 5,
                   color = ~ admissions_pal(mean_adm),
                   fillOpacity = 0.9,
                   popup = ~ paste("Board:", hb, br(), 
                                   "Mean admissions: ", round(mean_adm, 0))) %>% 
  addLegend(position = "topright",
            pal = admissions_pal,
            values = ~ mean_adm,
            title = "Mean admissions",
            opacity = 1
  )


# Naomi: occupancy heatmap for all of scotland
occupancy_pal <- colorNumeric(
  palette = "RdYlGn",
  domain = hospital_location_occupancy$percentage_occupancy)

occupancy_heatmap_all <- hospital_location_occupancy %>% 
  leaflet(options = leafletOptions(zoomSnap = 0.2, zoomDelta=0.2)) %>% 
  addProviderTiles(providers$Stamen.TonerLite) %>% 
  setView(-3.524194, 57.786499, zoom = 5.6) %>% 
  addCircleMarkers(lng = ~ longitude,
                   lat = ~ latitude,
                   weight = 0,
                   radius = 5,
                   fillColor = ~colorNumeric("RdYlGn", hospital_location_occupancy$percentage_occupancy)(percentage_occupancy),
                   #color = ~occupancy_pal(-percentage_occupancy),
                   fillOpacity = 0.9,
                   popup = ~ paste(location_name, br(), "Board:", hb, br(), 
                                   "Occupancy: ", round(percentage_occupancy,0), "%")
  ) %>% 
  addLegend(position = "topright",
            pal = colorNumeric("RdYlGn", hospital_location_occupancy$percentage_occupancy),
            values = ~ percentage_occupancy,
            title = "Occupancy (%)",
            opacity = 1
  )

# Ali: delayed discharges heatmap for all of scotland
map_plot <- map_means %>% 
  filter(HB != "SB0802",
         HB != "SB0801") %>% 
  leaflet(options = leafletOptions(zoomSnap = 0.2, zoomDelta=0.2)) %>% 
  setView(-3.524194, 57.786499, zoom = 5.6) %>% 
  addProviderTiles(providers$Stamen.TonerLite) %>%
  addCircleMarkers(lng = ~ longitude,
                   lat = ~ latitude,
                   weight = 0,
                   radius = 5,
                   fillColor = ~colorNumeric('RdYlGn', -185:185)
                   (-mean_diff),
                   fillOpacity = 0.9,
                   popup = ~ paste(Location, br(), "Board:", HB, br(), 
                                   "Difference in means: ",
                                   round(mean_diff, 0))
  ) %>% 
  addLegend(position = "topright",
            pal = colorNumeric("RdYlGn", -185:185),
            values = ~ c(185:-185),
            title = "Difference in means:",
            opacity = 1
  )

########### thijmen start ----
#### Open cleaned datasets of A&E attendances (demographics and specifying season terms) 

# 1. Open table specifying season
attendances_ae <- read.csv("cleaned_data/ae_attendences_cleaned.csv")

########
# 2. Open cleaned table for plotting demographics for  season 

demo_attendances_season <- read.csv("cleaned_data/demographics_ae_season_cleaned.csv")

##### 
# 3. Load in data for leaflet map
locations <- read.csv("cleaned_data/hospital_locations_clean.csv")

waiting_times <- read.csv("a_and_e/monthly_ae_activity_202305.csv") %>% 
  clean_names()

#thijmen end


