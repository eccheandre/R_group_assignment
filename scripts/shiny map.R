library(shiny)

ui <- shinyUI(fluidPage(
  titlePanel("Pollution map"),
  
  fluidRow(
    column(width = 3,
           helpText("Select a pollutant"),
           selectInput("pollutant", label = "Pollutant",
                       choices = parameters$param_Form, selected = 1)
    ),
    
    column(width = 3,
           helpText("Select a day"),
           dateInput("date", label = "Day", value = "2011-01-01", min = "2011-01-01", max = "2012-12-31",
                     format = "yyyy-mm-dd")
                       
    )
    
  ),
  
  leafletOutput("map", width = "100%", height = 500)
)
)

server <- shinyServer(function(input,output) {
  output$map = renderLeaflet({
    
    library(leaflet)
    
    # load example data (Fiji Earthquakes) + keep only 100 first lines
    map_data = subset(daily_data, ob_date == input$date & param_Form == input$pollutant, c("Lng", "Lat", "temp_avg", "station_Name", "Alt", "Type", "daily_avg"))
    min_v <- min(map_data$daily_avg)
    max_v <- max(map_data$daily_avg)
    
    # Create a color palette with handmade bins.
    mybins=seq(min_v, max_v, by=(max_v-min_v)/9)
    mypalette = colorBin( palette="YlOrRd", domain=map_data$daily_avg, na.color="black", bins=mybins)
    
    # Prepar the text for the tooltip:
    mytext=paste("Station: ", map_data$station_Name, "<br/>", paste0(input$pollutant, " value (microg/m^3): "), round(map_data$daily_avg, 1), "<br/>", "Temperature: ", map_data$temp_avg, "<br/>", "Altitude: ", map_data$Alt, "<br/>", "Station Type: ", map_data$Type, sep="") %>%
      lapply(htmltools::HTML)
    
    # Final Map
    style <- providers$Stamen.Toner
    leaflet(map_data) %>%  
      
      addTiles() %>% 
      
      #clearBounds()
      fitBounds(map_data$Lng[22],map_data$Lat[22],map_data$Lng[8],map_data$Lat[5]) %>%
      addProviderTiles("Esri.WorldImagery") %>%
      addProviderTiles(providers$Esri.WorldGrayCanvas) %>% addProviderTiles(providers$Stamen.TonerLabels) %>%
      addProviderTiles(providers$Stamen.TonerLines,options = providerTileOptions(opacity = 0.35)) %>%
      addCircleMarkers(~Lng, ~Lat, 
                       fillColor = ~mypalette(daily_avg), fillOpacity = 0.7, color="white", radius=25, stroke=F,
                       label = mytext,
                       labelOptions = labelOptions( style = list("font-weight" = "normal", padding = "3px 8px"), textsize = "13px", direction = "auto")
      ) %>%
      addLegend( pal=mypalette, values=~daily_avg, opacity=0.9, title = paste0(input$pollutant, " (microg/m^3)"), position = "bottomright" )
    
  })
})

# Run the application 
shinyApp(ui = ui, server = server)