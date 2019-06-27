#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(jsonlite)
library(DT)
library(curl)
library(plotly)
library(RColorBrewer)
library(dplyr)
library(maps)
library(viridis)

# Define server logic required to draw a histogram

countries <- read.csv("countries.csv")

countrieslist <- as.vector(countries$CountryName)
envinds <- read.csv("envinds.csv") 
envseries <- as.vector(envinds$Series)
urbaninds <- read.csv("urbaninds.csv")
urbanseries <- as.vector(urbaninds$Series)
pasteurl <- function(series){
  baseurl <- "https://unstats.un.org/SDGAPI/v1/sdg/Series/"
  paste(baseurl, series, "/GeoAreas", sep="")
}
checkcountries <- function(series){
  for (i in 1:length(series)){
    apiURLs <- as.vector(sapply(series, pasteurl))
    dat <- fromJSON(apiURLs[i])
    dat <- dat$geoAreaCode
    incountries <- as.numeric(as.vector(unlist(countries$M49 %in% dat)))
    countrieslist <- as.data.frame(cbind(countrieslist, incountries))
  }
  countrieslist
}


shinyServer(function(input, output) {
  
  countrieslist <- reactive({
    series <- input$series
    series <- as.vector(unlist((strsplit(series, split=" "))))
    if(input$env==TRUE){
      series<- c(envseries, series)
    }
    if(input$habitat==TRUE){
      series <- c(urbanseries, series)
    }
    countrieslist <- checkcountries(series)
    totmeans <- round((rowSums(sapply(countrieslist[, -1, drop=FALSE], as.numeric))-1)/(ncol(countrieslist)-1),3)
    countrieslist <- cbind(countries$M49, countrieslist, totmeans)
    names(countrieslist) <- c("M49 Code", "Country", series, "totmeans")
    return(countrieslist)
  }) 
  
  output$downloadData <- downloadHandler(
    filename = function(){
      paste("SDGcountriesreporting.csv")
    },
    content=function(file){
      write.csv(countrieslist(), file, row.names=FALSE)
    }
  )
  
  output$table <- DT::renderDataTable(DT::datatable({
    countrieslist()
   }))
  
  output$mymap <- renderPlotly({
    countrieslist <- countrieslist()
    
    avg_rep <- countrieslist[,c(2,ncol(countrieslist))]
    names(avg_rep) <- c("region", "avg_val")
    world_map <- map_data("world")
    map_dat <- left_join(world_map,avg_rep, by = "region")
    
    gmap <- ggplot(map_dat, aes(long, lat, group = group, fill=avg_val, text=paste0(region)))+
      geom_polygon(color = "black", size=0.1)+
      scale_fill_viridis_c(option = "D", direction=-1)+
      ggtitle("Percentage of the selected indicators that are reported in each country")
    ggplotly(gmap)
  })
  
  output$barplot <- renderPlotly({
    withProgress(message="Calculation in progress", 
                 detail="This may take a few minutes...", value=0,{
                   for (i in 1:15){
                     incProgress(1/15)
                     Sys.sleep(0.25)
                   }
                 })
    countrieslist <- countrieslist()
    
    LDCvalue <- round(mean(countrieslist$totmeans[which(countries$LDC==1)]), digits=3)
    LLDCvalue <- round(mean(countrieslist$totmeans[which(countries$LLDC==1)]), digits=3)
    SIDSvalue <- round(mean(countrieslist$totmeans[which(countries$SIDS==1)]), digits=3)
    OECDvalue <- round(mean(countrieslist$totmeans[which(countries$OECD==1)]), digits=3)
    totvalue <- round(mean(countrieslist$totmeans), digits=3)
    countrygroups <- c("LDC", "LLDC", "SIDS", "OECD", "World")
    tempdat <- as.data.frame(cbind(countrygroups,c(LDCvalue, LLDCvalue, SIDSvalue, OECDvalue, totvalue)))
    names(tempdat)<- c("group", "average_reporting")
    tempdat$group <- as.vector(tempdat$group)
    tempdat$average_reporting <- as.numeric(as.vector(tempdat$average_reporting))
    
    g <- ggplot(data=tempdat, aes(x=group, y=average_reporting, fill=group))+
      geom_bar(stat="identity")+
      theme(axis.title.y=element_blank(), axis.title.x=element_blank(), 
            legend.position="none")+
      ggtitle("Reporting Percentage by Country Groups")+
      scale_y_continuous(limits=c(0,1))
    ggplotly(g)
  })
  
  output$envinds <- DT::renderDataTable({
    DT::datatable(envinds, options=list(lengthMenu=c(5,10,15)))
  })
  
  output$urbaninds <- DT::renderDataTable({
    DT::datatable(urbaninds, options=list(lengthMenu=c(5,10,15)))
  })
  
})
