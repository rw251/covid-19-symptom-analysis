#install.packages("httr")
library(httr)
library(here)
library(dplyr)
library(ggplot2)
library(cowplot)

DATA_DIRECTORY <- file.path(here(), 'data-extraction', 'data')
OUTPUT_DIRECTORY <- file.path(here(), 'outputs')

# important covid-19 events
events <- data.frame(
  "Date" = as.Date(c("2020-01-30", "2020-03-05", "2020-03-23")), 
  "Event" = c("First UK case","First UK death","UK lockdown")
)
events$year<- "2020"
events$month <- strftime(events$Date, "%m")
events$day <- strftime(events$Date, "%d")
events$monthX <- as.numeric(events$month) + as.numeric(events$day) / 31 # approx location
events$week <- ceiling(as.numeric(strftime(events$Date, "%j")) / 7) # define days 1-7 as week 1, 8-14 as week 2 etc.
events$weekX <- 1 + as.numeric(strftime(events$Date, "%j")) / 7

loadDataFromFile <- function(filename, directory = DATA_DIRECTORY) {
  return(read.delim(file.path(directory, filename), sep = ','))
}

processData <- function(dat) {
  dat$inc <- dat[,2] # this should be the incidence variable (make sure incidence is always second and prevelence is third variable)
  dat$prev <- dat[,3]

  dat <- dat[,-c(2,3)]
  dat$Date <- as.Date(as.character(dat$Date), format = "%Y-%m-%d") # read date variable as dates rather than text

  dat$month <- strftime(dat$Date, "%m")
  dat$week <- ceiling(as.numeric(strftime(dat$Date, "%j")) / 7) # define days 1-7 as week 1, 8-14 as week 2 etc.

  dat <- dat %>%
    mutate(
      year = substr(Date,  1, 4),
      month = substr(Date,  6, 7),
      day = substr(Date, 9, 10))

  groupedByMonth <- dat %>% group_by(year, month) %>% summarise(n=n(), inc = sum(inc), prev = sum(prev))
  groupedByWeek <- dat %>% group_by(year, week) %>% summarise(n=n(), inc = sum(inc), prev = sum(prev))

  # Revove data from the current month and current week as it is not complete
  today <- Sys.time()
  monthToday<-strftime(today, "%m")
  weekToday<-ceiling(as.numeric(strftime(today, "%j")) / 7)
  lastWeek<-weekToday-1

  # NB need to be careful around the last week as sometimes the data is 0

  # for development we scale May
  scale <- 31/19 # we have data up to 19th May so proportionally might expect 31/19ths in the whole of May
  # for the real thing we'll include the whole of May

  groupedByMonth[(groupedByMonth$month==monthToday & groupedByMonth$year== "2020"),]$inc<-floor(groupedByMonth[(groupedByMonth$month==monthToday & groupedByMonth$year== "2020"),]$inc*scale)
  groupedByMonth[(groupedByMonth$month==monthToday & groupedByMonth$year== "2020"),]$prev<-floor(groupedByMonth[(groupedByMonth$month==monthToday & groupedByMonth$year== "2020"),]$prev*scale)
  groupedByWeek<-groupedByWeek[!(groupedByWeek$week==weekToday & groupedByWeek$year== "2020"),]
  #groupedByWeek<-groupedByWeek[!(groupedByWeek$week==lastWeek & groupedByWeek$year== "2020"),]

  # Remove week 53 - only has 2 or 3 days so would need scaling if kept in
  # - also we're comparing the effect in March-May so the end of December
  # isn't relevant
  groupedByWeek<-groupedByWeek[!(groupedByWeek$week==53),]

  return(list(groupedByWeek, groupedByMonth))
}

getTimeUnit = function(dat) {
  timeUnit<-'month'
  if('week' %in% colnames(dat)) {
    timeUnit<-'week'
  }
  return(timeUnit);
}

getAverageOfPreviousYears = function(dat) {
  # We're either grouping by the week or the month column
  timeUnit<-getTimeUnit(dat);
  previousYearsAveraged<-as.data.frame(dat 
    %>% filter(year != "2020") 
    %>% group_by_(.dots = list(timeUnit)) 
    %>% summarise(incSD=sd(inc, na.rm=TRUE), prevSD=sd(prev, na.rm=TRUE), inc = mean(inc), prev=mean(prev),n=n(), year='2015-2019 average', line_group='main')
  )
  prevSem <- previousYearsAveraged$prevSD/sqrt(previousYearsAveraged$n-1)
  incSem <- previousYearsAveraged$incSD/sqrt(previousYearsAveraged$n-1)
  previousYearsAveraged$prev_CI_lower <- previousYearsAveraged$prev + qt((1-0.95)/2, df=previousYearsAveraged$n-1)*prevSem
  previousYearsAveraged$prev_CI_upper <- previousYearsAveraged$prev - qt((1-0.95)/2, df=previousYearsAveraged$n-1)*prevSem
  previousYearsAveraged$inc_CI_lower <- previousYearsAveraged$inc + qt((1-0.95)/2, df=previousYearsAveraged$n-1)*incSem
  previousYearsAveraged$inc_CI_upper <- previousYearsAveraged$inc - qt((1-0.95)/2, df=previousYearsAveraged$n-1)*incSem
  thisYear<-as.data.frame(dat
    %>% filter(year=="2020") 
    # %>% group_by_(.dots = list(timeUnit)) 
    # %>% select_(.dots = list(timeUnit, 'inc', 'prev')) 
    # %>% mutate(year='2020', incSD=0, prevSD=0, n =1, prev_CI_lower=0,prev_CI_upper=0,inc_CI_lower=0,inc_CI_upper=0)
    %>% mutate(incSD=0, prevSD=0, n =1, prev_CI_lower=0,prev_CI_upper=0,inc_CI_lower=0,inc_CI_upper=0, line_group='main')
  )
  previousYears<-as.data.frame(dat
    %>% filter(year!="2020") 
    %>% mutate(incSD=0, prevSD=0, n =1, prev_CI_lower=0,prev_CI_upper=0,inc_CI_lower=0,inc_CI_upper=0, line_group='past')
  )
  return(rbind(previousYearsAveraged, thisYear, previousYears))
}

getNakedIncidencePlot <- function(data, timeUnit = getTimeUnit(data)) {
  data<-as.data.frame(data %>% filter(line_group == "main"))
  return(data %>% ggplot(aes_string(x=timeUnit, y='inc', group='year', color='year'))
    + geom_ribbon(aes(ymax = inc_CI_upper, ymin = pmax(0, inc_CI_lower)), fill='black',alpha=0.1,colour=NA)
    + geom_line()
    + theme(
        legend.position = "none",
        panel.grid = element_blank(),
        axis.title = element_blank(),
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank(),
        panel.background = element_blank(),
        plot.margin = unit(c(0, 0, 0, 0), "cm")
    )
  )
}

getIncidencePlot <- function(data, lowerCaseCondition, timeUnit = getTimeUnit(data), title = paste("Incidence of", lowerCaseCondition, "each", timeUnit, "between 2015 and 2020")) {

  # line from 2020 line upwards by 10
  maxInc <- max(data$inc)
  # events$ymin <- merge(data[, c("inc", timeUnit, "year")], events, by=c(timeUnit,"year"))$inc
  events$ymin <- 0
  events$ymax <- maxInc * 1.1

  # plot event labels at the correct point (e.g. not at week or month start)
  eventXPosition = paste(timeUnit, 'X', sep='');

  mainData<-as.data.frame(data %>% filter(line_group == "main"))
  pastData<-as.data.frame(data %>% filter(line_group == "past"))

  return(mainData %>% ggplot(aes_string(x=timeUnit, y='inc', group='year', color='year'))
    + geom_ribbon(aes(ymax = inc_CI_upper, ymin = pmax(0, inc_CI_lower)), fill='black',alpha=0.1,colour=NA)
    + geom_line(data=pastData, color='#cccccc', size=0.5)
    + geom_line(size=1.25)
    + labs(x = paste("Time (", timeUnit, ")"), y = "Incidence", color = "Year", title = title)
    + theme_light()

    # Events
    + geom_segment(data = events, mapping=aes_string(y='ymin', x=eventXPosition, xend=eventXPosition, yend='ymax'), colour='black')
    + geom_point(data = events, mapping=aes_string(x=eventXPosition, y='ymax'), size=1, colour='black')
    # + geom_label(data = events, mapping=aes_string(x=eventXPosition, y='ymax', label='Event', group=NA, color=NA), hjust=-0.1, vjust=0.1, size=3)
  )
}

drawIncidencePlot <- function(data, lowerCaseCondition, conditionNameDashed, directory = OUTPUT_DIRECTORY) {
  plot <- getIncidencePlot(data, lowerCaseCondition)
  plotFilename <- paste(conditionNameDashed, 'incidence', 'png', sep=".")
  ggsave(file.path(directory, plotFilename),plot + expand_limits(y = 0))
}

getNakedPrevalencePlot <- function(data, timeUnit = getTimeUnit(data)) {
  data<-as.data.frame(data %>% filter(line_group == "main"))
  return(data %>% ggplot(aes_string(x=timeUnit, y='prev', group='year', color='year'))
    + geom_ribbon(aes(ymax = prev_CI_upper, ymin = pmax(0, prev_CI_lower), fill="95% CI of 2015-2019"), fill='black',alpha=0.1,colour=NA)
    + geom_line()
    + theme(
        legend.position = "none",
        panel.grid = element_blank(),
        axis.title = element_blank(),
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank(),
        panel.background = element_blank(),
        plot.margin = unit(c(0, 0, 0, 0), "cm")
    )
  )
}

getPrevalencePlot <- function(data, lowerCaseCondition, timeUnit = getTimeUnit(data), title = paste("Prevalence of", lowerCaseCondition, "each", timeUnit, "between 2015 and 2020")) {
  # line from 2020 line upwards by 10
  maxPrev <- max(data$prev)
  # events$ymin <- merge(data[, c("prev", timeUnit, "year")], events, by=c(timeUnit,"year"))$prev
  events$ymin <- 0
  events$ymax <- maxPrev * 1.1

  # plot event labels at the correct point (e.g. not at week or month start)
  eventXPosition = paste(timeUnit, 'X', sep='');

  mainData<-as.data.frame(data %>% filter(line_group == "main"))
  pastData<-as.data.frame(data %>% filter(line_group == "past"))

  return(mainData %>% ggplot(aes_string(x=timeUnit, y='prev', group='year', color='year'))
    + geom_ribbon(aes(ymax = prev_CI_upper, ymin = pmax(0, prev_CI_lower), fill="95% CI of 2015-2019"), fill='black',alpha=0.1,colour=NA)
    + geom_line(data=pastData, color='#cccccc', size=0.5)
    + geom_line(size=1.25)
    + labs(x = paste("Time (", timeUnit, ")"), y = "Prevalence", color = "Year", title = title)
    + theme_light()

    # Events
    + geom_segment(data = events, mapping=aes_string(y='ymin', x=eventXPosition, xend=eventXPosition, yend='ymax'), colour='black')
    + geom_point(data = events, mapping=aes_string(x=eventXPosition, y='ymax'), size=1, colour='black')
    # + geom_label(data = events, mapping=aes_string(x=eventXPosition, y='ymax', label='Event', group=NA, color=NA), hjust=-0.1, vjust=0.1, size=3)
  )
}

drawPrevalencePlot <- function(data, lowerCaseCondition, conditionNameDashed, directory = OUTPUT_DIRECTORY) {
  plot <- getPrevalencePlot(data, lowerCaseCondition)
  plotFilename <- paste(conditionNameDashed, 'prevalence', 'png', sep=".")
  ggsave(file.path(directory, plotFilename),plot + expand_limits(y = 0))
}

drawCombinedPlotWithWeekAndMonth <- function(dataByWeek, dataByMonth, conditionNameLowerCase, conditionNameDashed, directory = OUTPUT_DIRECTORY) {

  incPlotByWeek <- getIncidencePlot(dataByWeek, conditionNameLowerCase, title = 'Incidence')
  incPlotByMonth <- getIncidencePlot(dataByMonth, conditionNameLowerCase, title = 'Incidence')
  prevPlotByWeek <- getPrevalencePlot(dataByWeek, conditionNameLowerCase, title = 'Prevalence')
  prevPlotByMonth <- getPrevalencePlot(dataByMonth, conditionNameLowerCase, title = 'Prevalence')

  plot_row_1 <- plot_grid(incPlotByWeek + expand_limits(y = 0), prevPlotByWeek + expand_limits(y = 0), labels = "AUTO")
  plot_row_2 <- plot_grid(incPlotByMonth + expand_limits(y = 0), prevPlotByMonth + expand_limits(y = 0), labels = "AUTO")

  titleText <- paste("Incidence and prevalence of", conditionNameLowerCase, "between 2015 and 2020")

  if(conditionNameLowerCase == "GROUP cancer") {
    titleText <- "Presenting incidence and prevalence of all malignant cancers 2015 to 2020"        
  } else if(conditionNameLowerCase == "GROUP cardiovascular") {
    titleText <- "Presenting incidence and prevalence of cardiovascular diagnoses 2015 to 2020"      
  } else if(conditionNameLowerCase == "GROUP mental health mild moderate") {
    titleText <- "Presenting incidence and prevalence of mild and moderate mental health conditions (anxiety and depression) 2015 to 2020"      
  } else if(conditionNameLowerCase == "GROUP mental health severe") {
    titleText <- "Presenting incidence and prevalence of severe mental health conditions (schizophrenia and bipolar) 2015 to 2020"      
  } else if(conditionNameLowerCase == "GROUP respiratory") {
    titleText <- "Presenting incidence and prevalence of respiratory conditions 2015 to 2020"      
  } 

  # now add the title
  title <- ggdraw() + 
    draw_label(
      titleText,
      fontface = 'bold',
      x = 0,
      hjust = 0
    ) +
    theme(
      # add margin on the left of the drawing canvas,
      # so title is aligned with left edge of first plot
      plot.margin = margin(0, 0, 0, 7)
    )
  plot <- plot_grid(
    title, plot_row_1, plot_row_2,
    ncol = 1,
    # rel_heights values control vertical title margins
    rel_heights = c(0.1, 1, 1)
  )

  plotFilename <- paste(conditionNameDashed, 'png', sep=".")
  save_plot(file.path(directory, plotFilename), plot, ncol = 2, base_height = 5)
}

drawCombinedPlot <- function(data, conditionNameLowerCase, conditionNameDashed, directory = OUTPUT_DIRECTORY) {
  timeUnit<-getTimeUnit(data);

  incPlot <- getIncidencePlot(data, conditionNameLowerCase, title = 'Incidence')
  prevPlot <- getPrevalencePlot(data, conditionNameLowerCase, title = 'Prevalence')

  plot_row <- plot_grid(incPlot + expand_limits(y = 0), prevPlot + expand_limits(y = 0), labels = "AUTO")

  # now add the title
  title <- ggdraw() + 
    draw_label(
      paste("Incidence and prevalence of", conditionNameLowerCase, "each", timeUnit, "between 2015 and 2020"),
      fontface = 'bold',
      x = 0,
      hjust = 0
    ) +
    theme(
      # add margin on the left of the drawing canvas,
      # so title is aligned with left edge of first plot
      plot.margin = margin(0, 0, 0, 7)
    )
  plot <- plot_grid(
    title, plot_row,
    ncol = 1,
    # rel_heights values control vertical title margins
    rel_heights = c(0.1, 1)
  )

  plotFilename <- paste(conditionNameDashed, timeUnit, 'png', sep=".")
  save_plot(file.path(directory, plotFilename), plot, ncol = 2)
}

# For some reason a Rplots.pdf is generated unless you call this
# see https://stackoverflow.com/a/38605858/596639
pdf(NULL)

proccessGroupFile <- function(file) {
  conditionNameDashed <- substr(file, 4, nchar(file) - 4)
  conditionNameParts <- strsplit(conditionNameDashed, '-')[[1]]
  conditionNameLowerCase <- paste(conditionNameParts, collapse=" ")

  cat('Doing ', conditionNameLowerCase, '\n')
  # load the file into R
  rawData <- loadDataFromFile(file)

  # Process the data into the correct format
  processedData <- processData(rawData)
  processedDataGroupedByWeek = processedData[[1]]
  processedDataGroupedByMonth = processedData[[2]]
  averagedDataByMonth <- getAverageOfPreviousYears(processedDataGroupedByMonth)
  averagedDataByWeek <- getAverageOfPreviousYears(processedDataGroupedByWeek)

  drawCombinedPlotWithWeekAndMonth(averagedDataByWeek, averagedDataByMonth, conditionNameLowerCase, conditionNameDashed)
}

processFile <- function(file) {
  conditionNameDashed <- substr(file, 4, nchar(file) - 4)
  conditionNameParts <- strsplit(conditionNameDashed, '-')[[1]]
  conditionNameLowerCase <- paste(conditionNameParts, collapse=" ")
  conditionNameUpperCase <- paste(toupper(substr(conditionNameParts,0,1)), substr(conditionNameParts,2,nchar(conditionNameParts)), sep="", collapse=" ")

  cat('Doing ', conditionNameLowerCase, '\n')
  # load the file into R
  rawData <- loadDataFromFile(file)

  # Process the data into the correct format
  processedData <- processData(rawData)
  processedDataGroupedByWeek = processedData[[1]]
  processedDataGroupedByMonth = processedData[[2]]
  averagedDataByMonth <- getAverageOfPreviousYears(processedDataGroupedByMonth)
  averagedDataByWeek <- getAverageOfPreviousYears(processedDataGroupedByWeek)

  # drawIncidencePlot(processedDataGroupedByWeek, conditionNameLowerCase, conditionNameDashed)
  # drawPrevalencePlot(processedDataGroupedByWeek, conditionNameLowerCase, conditionNameDashed)

  # drawCombinedPlot(averagedDataByMonth, conditionNameLowerCase, conditionNameDashed)
  # drawCombinedPlot(averagedDataByWeek, conditionNameLowerCase, conditionNameDashed)
  drawCombinedPlotWithWeekAndMonth(averagedDataByWeek, averagedDataByMonth, conditionNameLowerCase, conditionNameDashed)
}

processNbyMFiles <- function(directory, n = 1, m = 2, name, titleText ) {
  prefix <- paste("^dx-", name, "-", sep="")
  i<-1;
  myplots <- vector('list', m * n)
  # Cancer individual files
  for(file in list.files(DATA_DIRECTORY, pattern = prefix)) {

    conditionNameDashed <- substr(file, 4, nchar(file) - 4)
    conditionNameParts <- strsplit(gsub(paste(name,'-',sep=''), '', conditionNameDashed), '-')[[1]]
    conditionNameLowerCase <- paste(conditionNameParts, collapse=" ")
    conditionNameUpperCase <- paste(toupper(substr(conditionNameParts,0,1)), substr(conditionNameParts,2,nchar(conditionNameParts)), sep="", collapse=" ")

    cat('Doing ', conditionNameLowerCase, '\n')
    # load the file into R
    rawData <- loadDataFromFile(file)

    # Process the data into the correct format
    processedData <- processData(rawData)
    processedDataGroupedByWeek = processedData[[1]]
    processedDataGroupedByMonth = processedData[[2]]
    averagedDataByMonth <- getAverageOfPreviousYears(processedDataGroupedByMonth)
    averagedDataByWeek <- getAverageOfPreviousYears(processedDataGroupedByWeek)

    incPlotByWeek <- getNakedIncidencePlot(averagedDataByWeek)
    incPlotByMonth <- getNakedIncidencePlot(averagedDataByMonth)
    prevPlotByWeek <- getNakedPrevalencePlot(averagedDataByWeek)
    prevPlotByMonth <- getNakedPrevalencePlot(averagedDataByMonth)
    
    sub_plot_row_1 <- plot_grid(incPlotByWeek + expand_limits(y = 0), prevPlotByWeek + expand_limits(y = 0))
    # sub_plot_row_2 <- plot_grid(incPlotByMonth + labs(x="", y="") + expand_limits(y = 0) + theme(legend.position="none"), prevPlotByMonth + labs(x="", y="") + expand_limits(y = 0) + theme(legend.position="none"))
    title <- ggdraw() + 
      draw_label(
        conditionNameUpperCase,
        fontface = 'bold',
        x = 0,
        size=8,
        hjust = 0
      ) +
      theme(
        # add margin on the left of the drawing canvas,
        # so title is aligned with left edge of first plot
        plot.margin = margin(0, 0, 0, 20)
      )
    sub_plot <- plot_grid(title, sub_plot_row_1, ncol=1,
    # rel_heights values control vertical title margins
    rel_heights = c(0.1, 1))

    myplots[[i]] = sub_plot
    # if(i < 2) myplots[[i]] <-sub_plot_row_1
    i<-i+1
    
  }
  # now add the title
  title <- ggdraw() + 
    draw_label(
      titleText,
      fontface = 'bold',
      x = 0,
      size=12,
      hjust = 0
    ) +
    theme(
      # add margin on the left of the drawing canvas,
      # so title is aligned with left edge of first plot
      plot.margin = margin(0, 0, 0, 7)
    )
  plot_row_1 <- plot_grid(plotlist=myplots, ncol = n)
  plot <- plot_grid(
    title, plot_row_1,
    ncol = 1,
    # rel_heights values control vertical title margins
    rel_heights = c(m/10, m)
  )

  plotFilename <- paste(name,'individual', 'png', sep=".")
  save_plot(file.path(directory, plotFilename), plot, ncol = 2, base_height = 5)
}

processCancerFiles <- function(directory = OUTPUT_DIRECTORY) {
  processNbyMFiles(directory, n=4, m=5, name="cancer", titleText= "Weekly presenting incidence and prevalence of all malignant cancers 2015 to 2020")      
}

processCardiovascularFiles <- function(directory = OUTPUT_DIRECTORY) {
  processNbyMFiles(directory, n=2, m=4, name = "cardiovascular", titleText = "Weekly presenting incidence and prevalence of all cardiovascular diagnoses 2015 to 2020")
}

processModerateMentalHealth <- function(directory = OUTPUT_DIRECTORY) {
  processNbyMFiles(directory, n=1, m=2, name="mental-health-mild-moderate", titleText = "Weekly presenting incidence and prevalence of moderate mental health conditions 2015 to 2020")
}
processSevereMentalHealth <- function(directory = OUTPUT_DIRECTORY) {
  processNbyMFiles(directory, n=1, m=2, name="mental-health-severe", titleText = "Weekly presenting incidence and prevalence of severe mental health conditions 2015 to 2020")
}
processRespiratory <- function(directory = OUTPUT_DIRECTORY) {
  processNbyMFiles(directory, n=1, m=2, name="respiratory", titleText = "Weekly presenting incidence and prevalence of respiratory conditions 2015 to 2020")
}
# Do grouped ones first (purely because they're the first ones i look at)
for(file in list.files(DATA_DIRECTORY, pattern = "^dx-GROUP")) {
  proccessGroupFile(file);  
}

processCancerFiles();
processCardiovascularFiles();
processModerateMentalHealth();
processSevereMentalHealth();
processRespiratory();

# separate for self-harm
processFile('dx--self-harm.txt');
