library(neuralnet)
library(sp)
library(ggplot2)
library(raster)
library(vcd)

## initialize a pseudorandom number generator
set.seed(125)

#### import raster and data set ####
## raster
imp.reef <- raster::brick("data/Reef_20_2022_01_18_20cm_pix.tif")
imp.reef.sb <- raster("data/Reef_20_2022_01_18_20cm_pix.tif")

## dataset
sampled.points <- read.csv("data/TrainingSet.csv")

## plot
plot(imp.reef.sb)
points(sampled.points$Long, sampled.points$Lat, col = "red", pch = 16, cex = 0.5)

#### extract GB info ####
extracted.RGB <- raster::extract(imp.reef, sampled.points[, c("Long", "Lat")])
extracted.RGB <- as.data.frame(extracted.RGB)
## dataframe
my.dataset <- cbind(extracted.RGB[, (1:3)], sampled.points$CLASS)
colnames(my.dataset) <- c("R", "G", "B", "CLASS")

#### building training and test set ####
sample.values <- sample(1:nrow(my.dataset), 750)
training.set <- my.dataset[sample.values, ]
test.set <- my.dataset[-sample.values, ]


#### MLP training ####
nn.model <- neuralnet(CLASS ~ R + G + B, lifesign = "minimal", 
             data = training.set, hidden = c(9, 9), linear.output = FALSE, 
             rep = 1, stepmax = 1000000,
             threshold = 0.01)
plot(nn.model)

# saveRDS(nn.model, "D:/HIMB/MBIO630/Material/NN.model.RDS")
nn.model <- readRDS("output/NN.model.RDS")

#### MLP prediction ####
class.prediction <- predict(nn.model, test.set[, c(1:3)])
idx <- apply(class.prediction, 1, which.max)
predicted <- c('Reef', 'Sand', 'Water')[idx] #alphabetical order

## confusion matrix
cm <- table(predicted, test.set$CLASS)
cm

## kohen's kappa
res.k <- Kappa(cm)
res.k


#### MLP prediction on raster image ####
## dataframe of RGB values
all.rgb <- as.data.frame(matrix(nrow = length(imp.reef.sb), ncol = 3))
colnames(all.rgb) <- c('R', 'G', 'B')
all.rgb$R <- imp.reef$Reef_20_2022_01_18_20cm_pix.1[1:length(imp.reef.sb)]
all.rgb$G <- imp.reef$Reef_20_2022_01_18_20cm_pix.2[1:length(imp.reef.sb)]
all.rgb$B <- imp.reef$Reef_20_2022_01_18_20cm_pix.3[1:length(imp.reef.sb)]

## predict
class.prediction.all <- predict(nn.model, all.rgb)
idx.all <- apply(class.prediction.all, 1, which.max)
predicted.all <- c('Reef', 'Sand', 'Water')[idx.all] 

## plotting predicted classes on my raster
pred.reef <- imp.reef
pred.reef$Reef_20_2022_01_18_20cm_pix.4 <- idx.all
myColor <- c("darkorange", "yellow", "cyan3")

plot(pred.reef$Reef_20_2022_01_18_20cm_pix.4, breaks=c(0, 1, 2, 3), 
     col = myColor)

