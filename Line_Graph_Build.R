
library(ggplot2)
library(scales)

setwd("E:\\Sandbox")
options(width=200)


#####################################
### DATA IMPORT
#####################################
energy_df <- read.csv("DATA\\EIA Energy Consumption by Sector.csv")

str(energy_df)

cat(paste(unique(energy_df$Description), collapse ="\n"), "\n")

#####################################
### DATA CLEAN
#####################################
energy_df <- within(energy_df, {
  YYYYMM <- as.character(YYYYMM)
  Date <- as.Date(ifelse(substr(YYYYMM, 5, 6) != "13", 
                         paste0(YYYYMM, "01"),
                         paste0(substr(YYYYMM, 1, 4), "1231")),
                  format = "%Y%m%d")
  
  Sector <- factor(sapply(Description, function(d)
              switch(as.character(d),
                     "Primary Energy Consumed by the Residential Sector" = "Residential",
                     "Primary Energy Consumed by the Commercial Sector" = "Commercial",
                     "Primary Energy Consumed by the Industrial Sector" = "Industrial",
                     "Primary Energy Consumed by the Transportation Sector" = "Transportation",
                     "Primary Energy Consumed by the Electric Power Sector" = "Electric Power",
                     "Primary Energy Consumption Total"  = "All",
                     "Total Energy Consumed by the Residential Sector"   = "Residential",
                     "Total Energy Consumed by the Commercial Sector" = "Commercial",
                     "Total Energy Consumed by the Industrial Sector" = "Industrial",
                     "Total Energy Consumed by the Transportation Sector" = "Transportation",
                     "Energy Consumption Balancing Item" = "Other"
              )
            ))
  
  Energy_Type <- ifelse(grepl("Primary Energy", Description), "Primary",
                        ifelse(grepl("Total Energy", Description), "Total",
                               ifelse(Description == "Energy Consumption Balancing Item", "Other", NA)
                        )
                 )
})


str(energy_df)


#####################################
### PLOT BUILD
#####################################

### BASE R 
seaborn_palette <- c("#4C72B0", "#DD8452", "#55A868", "#C44E52", "#8172B3",
                     "#937860", "#DA8BC3", "#8C8C8C", "#CCB974", "#64B5CD")
                     
                     
plot_data <- subset(energy_df, Sector %in% c("Residential", "Commercial", "Industrial", "Transportation") &
                               Energy_Type == "Total" & format(Date, "%m") == "12" & format(Date, "%d") == "31")

plot_data$Sector <- factor(as.character(plot_data$Sector), levels=unique(as.character(plot_data$Sector)))

png("Line_Graph_Build_R_base.png", width=1200, height=600, unit="px")

  with(subset(plot_data, Sector=="Residential"), {
    par(mar = c(6,5,4,4), las=1)
    
    plot(Date, Value, type='l', pch=20,
         main = "Total U.S. Energy Consumption", xlab="\nDate", ylab="Trillion BTUs", font.lab=2,
         ylim=range(pretty(c(0, plot_data$Value))), yaxt="n",
         col=seaborn_palette[1], lwd=2, xaxt="n", xaxs="r", axes=FALSE,
         cex.main=1.75, cex.lab=1.5, cex.axis = 1.0)
    mtext("Source: U.S. Department of Energy, EIA", side=1, line=4, adj=0, cex=1)
    axis.Date(1, at = seq(min(Date), max(Date), along.with = unique(Date)),
              format="%Y", las=2, pos=0)
    axis(2, at=seq(5E3, 4E4, by=5E3), tck = 1, lty=1, col="lightgray", labels=NA, pos=-7670)
    axis(2, at=seq(0, 4E4, by=5E3), pos=-7670)
  })
  
  output <- by(plot_data, plot_data$Sector, function(sub) {
    with(sub, {
      lines(Date, Value, col=seaborn_palette[as.integer(Sector)], lwd=2) 
    })
  })
  
  legend("top", legend=unique(as.character(plot_data$Sector)), 
         ncol=4, col=seaborn_palette, lty=1, lwd=2, cex=1.25)
  
dev.off()



### GGPLOT 
energy_plot <- ggplot(plot_data, aes(Date, Value, color=Sector)) +
  geom_line(size = 0.75) +
  theme_bw() +
  labs(title="Total U.S. Energy Consumption", x="Date", y="Trillion BTUs") +
  theme(legend.position="top", plot.title = element_text(size=18, hjust=0.5),
        legend.title=element_text(size=12), legend.text=element_text(size=12), 
        legend.key.size = unit(0.75, "line"),
        axis.text=element_text(size=10), axis.title=element_text(size=14),
        axis.text.x=element_text(angle = 90, vjust=0.5),
        panel.grid.major.x = element_blank(), panel.grid.minor.x = element_blank()) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y", expand=c(0.01, 0.01)) +
  scale_y_continuous(labels = comma, n.breaks=9) +
  scale_color_manual(values = seaborn_palette) 


ggsave(filename = "Line_Graph_Build_R_gg.png", plot=energy_plot, 
       width=12, height=6, dpi=300, units="in", device='png')
  
 