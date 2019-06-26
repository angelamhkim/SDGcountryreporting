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
library(rworldmap)
library(plotly)
library(RColorBrewer)

# Define server logic required to draw a histogram

countries <- read.csv("countries.csv")

countrieslist <- as.vector(countries$CountryName)
envinds <- read.csv("envinds.csv") 
pasteurl <- function(series){
  baseurl <- "https://unstats.un.org/SDGAPI/v1/sdg/Series/"
  paste(baseurl, series, "/GeoAreas", sep="")
}
checkcountries <- function(series){
  for (i in 1:length(series)){
    apiURLs <- as.vector(sapply(series, pasteurl))
    dat <- fromJSON(apiURLs[i])
    dat <- dat$geoAreaName
    incountries <- as.numeric(as.vector(unlist(countries$CountryName %in% dat)))
    countrieslist <- as.data.frame(cbind(countrieslist, incountries))
  }
  names(countrieslist) <- c("Country", series)
  countrieslist
}


shinyServer(function(input, output) {
  
  countrieslist <- reactive({
    series <- input$series
    series <- as.vector(unlist((strsplit(series, split=" "))))
    if(input$env==TRUE){
      series<- c(series, "VC_DSR_DAFF", "VC_DSR_LSGP", "SG_DSR_LGRGSR", "SG_DSR_SILS", "ER_GRF_ANIMSTOR", 
                 "ER_RSK_LBRED", "SH_STA_ASAIRP", "SH_STA_WASH", "SH_STA_POISN", "SH_H2O_SAFE", 
                 "EN_WWT_WWDS", "EN_H2O_WBAMBQ", "ER_H2O_WUEYST", "ER_H2O_STRESS", "ER_H2O_IWRMD", 
                 "EG_TBA_H2CO", "EN_WBE_PMPP", "DC_TOF_WASHL", "ER_WAT_PART", "EG_EGY_CLEAN", 
                 "EG_FEC_RNEW", "EG_EGY_PRIM", "EN_MAT_DOMCMPG",  "EN_ATM_CO2MVA", "VC_DSR_DAFF", 
                 "VC_DSR_LSGP", "EN_REF_WASCOL", "EN_ATM_PM25", "SG_DSR_LGRGSR", "SG_DSR_SILS", 
                 "SG_SCP_CNTRY",   "EN_MAT_DOMCMPG", "SG_HAZ_CMRBASEL", "ER_FFS_PRTSPR", "VC_DSR_DAFF", 
                 "SG_DSR_LGRGSR", "SG_DSR_SILS", "ER_H2O_FWTL", "ER_MRN_MARIN", "ER_REG_UNFCIM", "ER_RDE_OSEX", 
                 "AG_LND_FRST", "ER_PTD_FRWRT", "ER_PTD_TERRS", "AG_LND_FRSTPRCT", "ER_PTD_MOTN", "ER_MTN_GRNCVI", 
                 "ER_RSK_LSTI", "ER_CBD_NAGOYA", "DC_ODA_BDVL", "DC_ODA_BDVL", "SG_INT_MBRDEV", "DC_FTA_TOTAL")
    }
    if(input$habitat==TRUE){
      series <- c(series, "EN_LND_SLUM")
    }
    countrieslist <- checkcountries(series)
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
  
  output$mymap <- renderPlot({
    countrieslist <- countrieslist()
    totmeans <- (rowSums(sapply(countrieslist[, -1, drop=FALSE], as.numeric))-1)/(ncol(countrieslist)-1)
    countrieslist <- cbind(countrieslist, totmeans)
    spdf <- joinCountryData2Map(countrieslist, joinCode="NAME", nameJoinColumn = "Country")
    mapCountryData(spdf, nameColumnToPlot = "totmeans", catMethod = "fixedWidth", mapTitle="Degree of Country-Level Reporting")
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
    
    totmeans <- (rowSums(sapply(countrieslist[, -1, drop=FALSE], as.numeric))-1)/(ncol(countrieslist)-1)
    
    LDCvalue <- mean(totmeans[which(countries$LDC==1)])
    LLDCvalue <- mean(totmeans[which(countries$LLDC==1)])
    SIDSvalue <- mean(totmeans[which(countries$SIDS==1)])
    OECDvalue <- mean(totmeans[which(countries$OECD==1)])
    countrygroups <- c("LDC", "LLDC", "SIDS", "OECD")
    tempdat <- as.data.frame(cbind(countrygroups,c(LDCvalue, LLDCvalue, SIDSvalue, OECDvalue)))
    names(tempdat)<- c("group", "average_reporting")
    
    g <- ggplot(data=tempdat, aes(x=group, y=average_reporting, fill=average_reporting))+
      geom_bar(stat="identity")+
      theme(axis.text.y=element_blank(), axis.title.y=element_blank(), axis.title.x=element_blank(), 
            legend.position="none")+
      ggtitle("Reporting Percentage by Country Groups")
    ggplotly(g)
  })
  
  output$envinds <- DT::renderDataTable({
    DT::datatable(envinds, options=list(lengthMenu=c(5,10,15)))
  })
  
  output$urbaninds <- DT::renderDataTable({
    DT::datatable(urbaninds, options=list(lengthMenu=c(5,10,15)))
  })
  
})
