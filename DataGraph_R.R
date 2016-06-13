library(ggplot2)

setwd("C:/Path/To/DATA_GRAPH")

# MULTI-FACTOR PRODUCT DATA
mfpdf <- read.table(paste0(getwd(), "/DATA/MultifactorProductData.txt"), sep="\t", 
                    header = TRUE, row.names = NULL, stringsAsFactors = FALSE)
mfpdf$sector_code <- as.integer(substr(mfpdf$series_id, 4, 7))
mfpdf$type <- substr(mfpdf$series_id, 4, 7)
mfpdf$footnote_codes <- NULL
mfpdf <- mfpdf[substr(mfpdf$series_id,8, 10) == '012',]

# SECTOR DATA
sectordf <- read.table(paste0(getwd(), "/DATA/MultifactorSectorData.txt"), sep="\t", 
                       header = TRUE, row.names = NULL, stringsAsFactors = FALSE)
names(sectordf) <- c("sector_code","sector_name","display_level","selectable","sort_sequence")
sectordf[,6] <- NULL
sectordf <- sectordf[c("sector_code","sector_name")]

# MERGE AND SPLIT SECTOR NAME VALUE
df <- merge(mfpdf, sectordf, by='sector_code')
df <- cbind(df, list(NAICS=do.call(rbind, regmatches(df$sector_name, 
                                      gregexpr('(\\(NAICS.*)', df$sector_name)
                           )
                    ))
            )
df$sector_name <- gsub(" (\\(NAICS.*)", "", df$sector_name)

# RUN GRAPHS
ppi <- 300
mfpplots <- lapply(unique(df$sector_code), function(i){
                    png(paste0(getwd(), '/GRAPHS/sector_', i, '_r.png'),
                        width=16*ppi, height=6*ppi, res=ppi)
  
                    print(ggplot(df[df$sector_code==i,], aes(x=sector_name, y=value, fill=factor(year))) + 
                            geom_bar(width = 0.8, stat="identity", position = position_dodge(width = 0.9)) +
                            guides(fill=guide_legend(title="Year", nrow=2)) + ylim(0,125) +
                            labs(title="U.S. MultiFactor Productivity, 1987-2015", y="MultiFactor Product", x="Industry Sector") +
                            theme(legend.position="bottom") + scale_fill_hue(l=45))
                    
                    dev.off()
             })