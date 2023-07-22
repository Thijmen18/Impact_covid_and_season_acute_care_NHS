# server -----
server <- function(input, output, session) {
  
  # render PHS logo
  # 
  # output$PHSlogo <- renderImage({
  #   list(src = "../images/phs-logo.png",
  #        width = 100,
  #        height = 60,
  #        alt = "Public Health Scotland")
  # })
  
# Naomi plots start ----
  # output$occupancy_heatmap_all ----
  # static, shows all of scotland
  output$occupancy_heatmap_all <- renderLeaflet({
    occupancy_heatmap_all
  })
  
  
  # output$occupancy_heatmap ----
  # reactive to hb selector
  output$occupancy_heatmap <- renderLeaflet({
    hospital_location_occupancy %>% 
      filter(hb == input$hb) %>% 
      leaflet() %>% 
      addProviderTiles(providers$Stamen.TonerLite) %>% 
      addCircleMarkers(lng = ~ longitude,
                       lat = ~ latitude,
                       weight = 1,
                       radius = 5,
                       fillOpacity = 1,
                       popup = ~ paste(location_name, br(), "Board:", hb, br(), 
                                       "Occupancy: ", round(percentage_occupancy,0), "%"),
                       color = ~ occupancy_pal(percentage_occupancy)
      )
  })
  
  # output$occupancy_ts ----
  
  # plot occupancy over time with hb filter
  # assign to plot_ts_occupancy_filter_hb
  # note scale all health boards == individual HB so keep on same graph
  output$occupancy_ts <- renderPlot({
    occupancy_per_hb %>% 
      # filter for hb, always show "all of scotland" = S92000003
      filter(hb %in% c("S92000003", input$hb)) %>% 
      ggplot() +
      aes(x = quarter, y = percentage_occupancy, colour = hb) +
      geom_line(show.legend = FALSE) +
      geom_point(show.legend = FALSE) +
      scale_colour_manual(values = scot_hb_colours) +
      labs(x = "\nYear quarter", y = "Percentage occupancy\n",
           title = "Percentage occupancy (hospital beds)",
           colour = "Health board") +
      theme_penguin()
  })
# Naomi plots end

# Thijmen start ----
  # Thijmen - output plot for season difference
  output$plot_season <- renderPlot({
    ggplot() +
      geom_col(data = 
                 attendances_ae %>% 
                 filter(right_season == TRUE) %>% 
                 group_by(year, season, hbt) %>% 
                 summarise(total_attendances = sum(number_of_attendances_all)) %>%
                 filter(year < 2020 & year > 2007) %>% 
                 filter(hbt == input$hb), 
               aes(
                 x = year, 
                 y = total_attendances, 
                 fill = season),
               position = "dodge", col = "white") +
      geom_line(data = 
                  attendances_ae %>% 
                  select(year, hbt, number_of_attendances_all) %>% 
                  group_by(year, hbt) %>% 
                  summarise(average_season_year = sum(number_of_attendances_all)/4) %>% 
                  filter(year < 2020 & year > 2007) %>%
                  filter(hbt == input$hb), 
                aes(
                  x = year, 
                  y = average_season_year)) +
      labs(title = "Number of A&E attendances per year, per season",
           subtitle = "line indicating average number of attendances per season per year",
           x = "\nYear", y = "Total attendances\n",
           fill = "Season") +
      scale_y_continuous(labels = scales::comma) +
      scale_fill_manual(values = season_colours) +
      theme_penguin() +
      theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)) +
      scale_x_continuous(breaks = c(2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019))
    
  })
  
  # Thijmen - output plot with demographics - focus on deprivation
  output$plot_season_demo_simd <- renderPlot({
    
    demo_attendances_season %>% 
      filter(right_season == TRUE) %>% 
      filter(year < 2020 & year > 2007) %>% 
      filter(hbt == input$hb) %>% 
      select(year, season, hbt, deprivation, number_of_attendances) %>% 
      mutate(deprivation = as.character(deprivation)) %>%
      replace_na(list(deprivation = "unknown")) %>% 
      group_by(year, season, hbt, deprivation) %>% 
      summarise(total_per_deprivation = sum(number_of_attendances)) %>% 
      ggplot() +
      aes(x = as.character(year), y = total_per_deprivation, fill = as.character(deprivation), group = season) +
      geom_col(position = "dodge", col = "white") +
      labs(title = "Number of attendances split by SIMD",
           x = "\nYear", y = "Attendances\n",
           fill = "SIMD") +
      theme_penguin()
    
  })
  
  # Thijmen - output plot with demographics - focus on age
  output$plot_season_demo_age <- renderPlot({
    
    demo_attendances_season %>% 
      filter(right_season == TRUE) %>% 
      filter(year < 2020 & year > 2007) %>% 
      filter(hbt == input$hb) %>% 
      select(year, season, hbt, age, number_of_attendances) %>% 
      group_by(year, season, hbt, age) %>% 
      summarise(total_per_age = sum(number_of_attendances)) %>% 
      ggplot() +
      aes(x = as.character(year), y = total_per_age, fill = as.character(age), group = season) +
      geom_col(position = "dodge", col = "white") +
      labs(title = "Number of attendances split by age group",
           x = "\nYear", y = "Attendances\n",
           fill = "Age group") +
      theme_penguin()
    
  })
  
  # Thijmen - output map leaflet plot
  output$attendance_season_heatmap <- renderLeaflet({
    waiting_times %>% 
      rename("Location" = "treatment_location") %>% 
      left_join(locations, by = "Location") %>% 
      filter(hbt == input$hb) %>% 
      leaflet() %>% 
      addProviderTiles(providers$Stamen.TonerLite) %>%
      addCircleMarkers(lng = ~ longitude,
                       lat = ~ latitude,
                       weight = 0,
                       fillOpacity = 0.9,
                       fillColor = "darkviolet",
                       popup = ~ paste(department_type))
  })
#Thijmen end
  
  
# Chiara plots start ----

  output$admissions_heatmap <- renderLeaflet({
    admissions_heatmap
  })
  
  output$admissions_ts <- renderPlot({
    ha_demo %>% 
      filter(hb %in% c(input$hb)) %>% 
      group_by(hb, month_ending_date) %>% 
      summarise(mean_admissions = mean(number_admissions)) %>% 
      ggplot() +
      aes(x = month_ending_date, y = mean_admissions, group = hb, colour = hb) +
      geom_line(show.legend = FALSE) +
      geom_point(show.legend = FALSE) +
      scale_colour_manual(values = scot_hb_colours) +
      labs(
        title = "Hospital admissions trend per health Board",
        x = "\nYear",
        y = "average monthly hospital admissions\n"
      ) +
      theme_penguin()
  })
  
  output$admissions_plot <- renderPlot({
    ha_demo %>% 
      filter(hb %in% c(input$hb), age != "All ages") %>%
      group_by(age, month_ending_date) %>% 
      summarise(mean_admissions = mean(number_admissions)) %>% 
      ggplot() +
      aes(x = month_ending_date, y = mean_admissions, group = age, colour = age) +
      geom_line() +
      geom_point() +
      scale_colour_manual(values = age_colours) +
      labs(
        title = "Hospital admissions depending on age",
        x = "\nYear",
        y = "average monthly hospital admissions\n"
      ) +
      theme_penguin()
  })
  
  
# Chiara plots end
 
# Ali start ----
  
  output$delays_age <- renderPlot({
    delayed %>%
      filter(hbt == input$hb,
             reason_for_delay == "All Delay Reasons") %>% 
      ggplot() +
      aes(x = month_of_delay,
          y = average_daily_number_of_delayed_beds,
          group = age_group, colour = age_group) +
      geom_line() +
      geom_point(size = 1) +
      labs(title = "Average Daily Number of Delayed Beds",
           x = "\nYear",
           y = "Average Daily Number of Delayed Beds\n",
           colour = "Age Group") +
      theme_penguin()
  })
  
  output$delays_map <- renderLeaflet({
    map_plot
  })
  
  
  # Ali end
  
}

