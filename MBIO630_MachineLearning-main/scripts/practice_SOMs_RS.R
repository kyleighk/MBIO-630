library(kohonen)
library(kohonen2)
library(ggplot2)
library(raster)
library(reshape2)

## initialize a pseudorandom number generator
set.seed(42)

#### import raster ####
waikiki_8_19.sb <- raster("/Users/kyleighkuball/Documents/Documents - Kyleigh’s MacBook Pro/Madin Lab/Liz Madin class/MBIO630_GroupProject_MeasuringReefs-main/data/waikiki 8:19 .jpg")
print(waikiki_8_19.sb)
waikiki_8_19 <- raster::brick("/Users/kyleighkuball/Documents/Documents - Kyleigh’s MacBook Pro/Madin Lab/Liz Madin class/MBIO630_GroupProject_MeasuringReefs-main/data/waikiki 8:19 .jpg")
print(waikiki_8_19)

#### sampling RGB data from random sample ####

## select the number of random points for training data
sample.size <- 100000
sample.values <- sample(1:length(waikiki_8_19.sb), sample.size, replace = F)

## extracting geoinformation
sample.coor <- as.data.frame(xyFromCell(waikiki_8_19, sample.values))
colnames(sample.coor) <- c("Lon", "Lat")

# plotting
plot(waikiki_8_19.sb)
points(sample.coor$Lon, sample.coor$Lat, col = "red", pch = 16, cex = 0.5)

## generate dataframe of selected RGB vectors
sample.rgb <- as.data.frame(matrix(nrow = sample.size, ncol = 3))
colnames(sample.rgb) <- c('R', 'G', 'B')

sample.rgb$R <- waikiki_8_19$waikiki_8.19_.1[sample.values]
sample.rgb$G <- waikiki_8_19$waikiki_8.19_.2[sample.values]
sample.rgb$B <- waikiki_8_19$waikiki_8.19_.3[sample.values]

#### train the SOM ####

## define a grid for the SOM and train
grid.size <- ceiling(sample.size ^ (1/2.5))
som.grid <- somgrid(xdim = grid.size, ydim = grid.size, topo = 'hexagonal')
som.model <- kohonen2::som(data.matrix(sample.rgb), grid = som.grid, toroidal = TRUE)

## extract some data to make it easier to use
som.events <- som.model$codes
som.events.colors <- rgb(som.events[,1], som.events[,2], som.events[,3], maxColorValue = 255)
som.dist <- as.matrix(dist(som.events))

## generate a plot of the untrained data.  this isn't really the configuration at first iteration, but
## serves as an example
col.func <- colorRampPalette(c("grey","forestgreen", "darkolivegreen1", "orange"))

plot(som.model,
     type = 'mapping',
     bgcol = som.events.colors[sample.int(length(som.events.colors), size = length(som.events.colors))],
     keepMargins = F,
     col = NA,
     main = '')

## generate a plot after training.
lbl <- c(".")
plot(som.model,
     type = 'mapping',
     bg = som.events.colors,
     keepMargins = F,
     col = NA,
     main = '',
     labels = lbl)


## lets take a look to the RGB values distribution
i <- 3 # where 1=R, 2=G, 3=B

plot.kohonen(som.model, type = "property", property = som.model$codes[,i], 
             main = colnames(sample.rgb)[i],
             palette.name = col.func)
 add.cluster.boundaries(som.model, som_cluster)

#### clustering ####

## define colors and clusters
myColor <- c("cyan3","darkorange", "yellow", "white")
col.func <- colorRampPalette(c("grey","forestgreen", "darkolivegreen1", "orange"))
som_cluster <- cutree(hclust(dist(som.model$codes)), 4) # search "Average Silohuette Method for optimizing K
bgcolors <- myColor[som_cluster]


plot.kohonen(som.model,
     type = 'mapping',
     keepMargins = F,
     col = NA,
     main = '')

## histograms of RGB values per class
sample.rgb.classes <- som_cluster[som.model$unit.classif]
sample.rgb$CLASS <- sample.rgb.classes
melt.sample.rgb <- melt(sample.rgb, id = c("CLASS"))

ggplot(melt.sample.rgb, aes(value, fill = variable)) + 
  geom_histogram(bins = 10) + 
  facet_wrap(~CLASS, scales = 'free_x')

#### predciting ####
all.cells <- 1:length(imp.reef.sb)
pred.cells <- all.cells[-sample.values]
new.data <- as.data.frame(matrix(nrow = length(imp.reef.sb)-sample.size, ncol = 3))
colnames(new.data) <- c('R', 'G', 'B')

new.data$R <- imp.reef$Reef_20_2022_01_18_20cm_pix.1[pred.cells]
new.data$G <- imp.reef$Reef_20_2022_01_18_20cm_pix.2[pred.cells]
new.data$B <- imp.reef$Reef_20_2022_01_18_20cm_pix.3[pred.cells]


new.data.units <- map.kohonen(som.model, newdata = data.matrix(new.data))
sample.data.units <- map.kohonen(som.model, newdata = data.matrix(sample.rgb))

## get the classification for closest map units
new.data.classes <- som_cluster[new.data.units$unit.classif]
sample.data.classes <- som_cluster[sample.data.units$unit.classif]

# building my final matrix
class.mat <- matrix(NA, nrow = length(imp.reef.sb), ncol = 4) 
class.mat[sample.values, 1] <-  sample.rgb$R
class.mat[-sample.values, 1] <- new.data$R
class.mat[sample.values, 2] <-  sample.rgb$G
class.mat[-sample.values, 2] <- new.data$G
class.mat[sample.values, 3] <-  sample.rgb$B
class.mat[-sample.values, 3] <- new.data$B
class.mat[sample.values, 4] <-  sample.data.classes
class.mat[-sample.values, 4] <- new.data.classes

# plotting predicted classes on my raster
pred.reef <- imp.reef
pred.reef$Reef_20_2022_01_18_20cm_pix.4 <- class.mat[ ,4]

plot(pred.reef$Reef_20_2022_01_18_20cm_pix.4, breaks = c(0, 1, 2, 3, 4), 
     col = myColor)
