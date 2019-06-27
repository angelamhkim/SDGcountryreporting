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
      menuItem("Indicators List", tabName="info", icon=icon("list")),
      menuItem("About", tabName="about", icon=icon("question-circle"))
    ),
    h4("Select indicators"),
    textInput("series", label="Series SDMX codes", value="VC_DSR_DAFF"),
    h6("Go to the Indicators List tab to see which indicators are included in Environmental Indicators and Habitat Indicators"),
    checkboxInput("env", "Environmental indicators", value=FALSE),
    checkboxInput("habitat", "UN-Habitat indicators", value=FALSE),
    submitButton("Submit", icon=icon("arrow-right"))
    
  ),
  
  dashboardBody(
    tabItems(
      tabItem("dashboard",
              fluidRow(
                plotlyOutput("barplot"),
                plotlyOutput("mymap")
              )),
      tabItem("rawdat", 
              fluidRow(
                h5("If there are too many indicators and you can't see all rows, download the table and view in Excel."),
                DT::dataTableOutput('table'),
                downloadButton("downloadData", "Download as csv")
              )),
      tabItem("info",
              fluidRow(
                h5("To add more indicators beyond the ones listed in the tables below, enter the SDMX codes to the input box in 
                   the side panel separated by a space and those will be appended to the end of the set list."),
                h3("Environmental Indicators",icon("leaf")),
                h5("The list of environment-related SDG indicators is based on that used for GEO-6."),
                DT::dataTableOutput('envinds'),
                h3("UN-Habitat Indicators", icon("city")),
                h5("The list of urban indicators were chosen by me."),
                DT::dataTableOutput("urbaninds")
              )),
      tabItem("about",
              fluidRow(
                column(10, 
                  h4("This application shows the degree of country-level reporting for selected SDG indicators based on their SDMX codes.
                   The codes can be found on the SDG Global Indicators Database: https://unstats.un.org/sdgs/indicators/database/"),
                  h4("The source code for this application can be found on this GitHub repository: 
                     https://github.com/angelamhkim/SDGcountryreporting")
                )
              ))
    
)))


