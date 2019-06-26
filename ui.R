#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinydashboard)
library(plotly)

dashboardPage(
  dashboardHeader(title = "SDG Reporting"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Dashboard", tabName = "dashboard", icon=icon("tachometer-alt")),
      menuItem("Data Table", tabName="rawdat", icon=icon("table")),
      menuItem("Indicators List", tabName="info", icon=icon("question-circle"))
    ),
    h4("Select indicators"),
    textInput("series", label="Series SDMX codes", value="VC_DSR_DAFF"),
    checkboxInput("env", "Environmental indicators", value=FALSE),
    checkboxInput("habitat", "UN-Habitat indicators", value=FALSE),
    actionButton("goButton", "Submit", icon=icon("arrow-right"))
    
  ),
  
  dashboardBody(
    tabItems(
      tabItem("dashboard",
              fluidRow(
                plotlyOutput("barplot"),
                plotOutput("mymap")
              )),
      tabItem("rawdat", 
              fluidRow(
                downloadButton("downloadData", "Download as csv"), 
                DT::dataTableOutput('table')
              )),
      tabItem("info",
              fluidRow(
                h3("Environmental Indicators",icon("leaf")),
                h5("To add more indicators beyond the ones listed in the table below, enter the SDMX codes to the input box in 
                   the side panel separated by a space and those will be added to the list of Environmental Indicators."),
                DT::dataTableOutput('envinds'),
                h3("UN-Habitat Indicators", icon("city")),
                DT::dataTableOutput("urbaninds")
              ))
    
)))


