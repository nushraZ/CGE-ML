library(tidyverse)
library(rio)
library(caret)
library(rpart)
library(glmnet)
library(car)
library(MASS)  #for M-estimation method of robust regression: rlm
library(corrplot)
library(coefplot)
library(readxl)
library(corrplot)
library(tidyr)
library(ggbiplot)
library(dplyr)
library(randomForest)

#setting the current directory
setwd("/Users/nushra/Documents/University/_Research")

## ------------------------- Functions to process the data -------------------------------------

#method for data processing (CGE output and shocks)
processCGESimData <- function(df)
{
  require(dplyr)
  require(stringr)
  
  names(df)[1] <- "dummy"
  #df[1:51,"dummy"] 
  newNamesDDS <- df[1:75,"dummy"] # there are 48 (72 for DFFD) CGE output columns for the analysis, (sector-puma comb)
  temp <- t(df[1:75,]) 
  colnames(temp)<-newNamesDDS
  temp <- temp[-1,]
  temp <- as.data.frame(temp[ , colSums(is.na(temp))==0])
  temp$ID <- row.names(temp) %>% str_remove("R")
  temp <- as.data.frame(apply(temp, 2, as.numeric))
  return(temp %>% dplyr::select(ID, everything()))
}

##--------------------------Reading excel data files-------------------------------
# specifying the path name
path <- "./_final/MMSA_Shelby_GAMS_Outputs_corrected.xlsx"   #note: this data only contains the 510 input or output observations associated with the CGE converged simulations
# reading data from all sheets
data <- import_list(path)

### Reading in the BaseKap

baseKapDF <- data$base_cap
#sorting alphabetically on sector column
baseKapDF <- baseKapDF[order(baseKapDF$sector),] 

# -----------creating the transposed CGE output dataframes and processing hazard Info --------------

# -- delta domestic supply (DDST) -- units: millions of USD
DDST <- processCGESimData(data$DDS)     
DDST$epicenter <- as.factor(paste(DDST$Latitude, DDST$Longitude, sep = ",")) #lat long format
DDST$Magnitude <- as.factor(DDST$Magnitude)

#Dropping LAT LONG as I have them in Epicenter format
DDST$Latitude <- NULL
DDST$Longitude <- NULL

str(DDST)

# -- delta household income (DYT) -- units: millions of USD
DYT <- processCGESimData(data$DY)   
DYT$epicenter <- as.factor(paste(DYT$Latitude, DYT$Longitude, sep = ",")) #lat long format
DYT$Magnitude <- as.factor(DYT$Magnitude)

#Dropping LAT LONG as I have them in Epicenter format
DYT$Latitude <- NULL
DYT$Longitude <- NULL

str(DYT)
# -- migration (MIGT) -- units: #households
MIGT <- processCGESimData(data$MIGT) 
MIGT$epicenter <- as.factor(paste(MIGT$Latitude, MIGT$Longitude, sep = ",")) #lat long format
MIGT$Magnitude <- as.factor(MIGT$Magnitude)

#Dropping LAT LONG as I have them in Epicenter format
MIGT$Latitude <- NULL
MIGT$Longitude <- NULL

str(MIGT)
# -- delta employment(DFFDT) -- units: #employment
DFFDT <- processCGESimData(data$DFFD) 
DFFDT$epicenter <- as.factor(paste(DFFDT$Latitude, DFFDT$Longitude, sep = ",")) #lat long format
DFFDT$Magnitude <- as.factor(DFFDT$Magnitude)

#Dropping LAT LONG as I have them in Epicenter format
DFFDT$Latitude <- NULL
DFFDT$Longitude <- NULL

str(DFFDT)

## ---------------------------- Processing the SHOCKS data ---------------------------------------

SHOCKS <- processCGESimData(data$shocks) #using data that ran on CGE model

SHOCKS$epicenter <- as.factor(paste(SHOCKS$Latitude, SHOCKS$Longitude, sep = ",")) #lat long format
SHOCKS$Magnitude <- as.factor(SHOCKS$Magnitude)

#Dropping LAT LONG as I have them in Epicenter format
SHOCKS$Latitude <- NULL
SHOCKS$Longitude <- NULL

str(SHOCKS)

## Fixing Naming convention problem that arises in line 131: SHOCKSval
SHOCKS <- SHOCKS %>%
  rename_with(
    ~ paste0(toupper(substring(., 0, 1)), #converting first letter to upper "G" for GOODS
             tolower(substring(., 2, 5)), #converting the next letters to lower "oods" for "OODS"
             substring(., 6)), #keeping the last letter as it is
    starts_with(c("GOODS", "TRADE", "OTHER")))

#convert the capital stock REMAINING to capital stock LOST
SHOCKS <- SHOCKS %>%
  mutate_at(vars(-ID), function(x) if(is.numeric(x)) 1 - x else x)# excluding ID (numeric), and applying 1-x to all numeric cols

#scale shocks by base kap
#scaling KAP Lost in Shocks by the corresponding base KAP
SHOCKS$ID <- as.factor(SHOCKS$ID)
SHOCKSval <- dplyr::mutate(SHOCKS, across(where(is.numeric), ~.x*baseKapDF[baseKapDF$sector==cur_column(),2])) 

#quick histogram of total shock values
SHOCKSval %>% dplyr::mutate(total = rowSums(across(where(is.numeric)))) %>% ggplot(aes(x=total)) + geom_histogram(bins=12)


###### ----------------------- Preprocessing Datasets --------------------------------
## ---------------------- DDST: Delta Domestic Supply ----------------------------

outcomes_dds <- data.frame(ID=as.factor(DDST$ID), 
                           totDDS = apply(DDST[,-c(1, 50, 51)],1,sum),  #sum(total DDS); all columns except ID,M,epicenter 
                           cDDS = apply(DDST[,2:25],1,sum),  #sum(commercial DDS)
                           rDDS = apply(DDST[26:49],1,sum))  #sum(residential DDS)
#quick check on the values
outcomes_dds %>% ggplot(aes(x=totDDS)) + geom_histogram(bins= 20)
outcomes_dds %>% ggplot(aes(x=cDDS)) + geom_histogram(bins=20)
outcomes_dds %>% ggplot(aes(x=rDDS)) + geom_histogram(bins= 20)

#put input and output together
mdl_dds <- SHOCKSval %>% left_join(outcomes_dds, by="ID")

#Adding a new column totDamage. 
mdl_dds <- mdl_dds %>% dplyr::mutate(totDamage = rowSums(dplyr::select(.,GoodsA:TradeH))) #"." specifies the df we are currently working with

## ---------------------- DYT: Delta HH Income ----------------------------

outcomes_DY <- data.frame(ID=as.factor(DYT$ID), 
                          totDY = apply(DYT[,-c(1, 42, 43)],1,sum))  
#quick check on the values
outcomes_DY %>% ggplot(aes(x=totDY)) + geom_histogram(bins= 20)

#put input and output together
mdl_DY<- SHOCKSval %>% left_join(outcomes_DY, by="ID")

## ---------------------- MIGT: Delta HH numbers ----------------------------

outcomes_MIGT <- data.frame(ID=as.factor(MIGT$ID), 
                            totMIGT = apply(MIGT[,-c(1, 42, 43)],1,sum))  
#quick check on the values
outcomes_MIGT %>% ggplot(aes(x=totMIGT)) + geom_histogram(bins= 20)

#put input and output together
mdl_MIGT<- SHOCKSval %>% left_join(outcomes_MIGT, by="ID")

## ---------------------- DFFD: Delta Employment ----------------------------

outcomes_DFFD <- data.frame(ID=as.factor(DFFDT$ID), 
                            totDFFD = apply(DFFDT[,-c(1, 74, 75)],1,sum))  
#quick check on the values
outcomes_DFFD %>% ggplot(aes(x=totDFFD)) + geom_histogram(bins= 20)

#put input and output together
mdl_DFFD<- SHOCKSval %>% left_join(outcomes_DFFD, by="ID")

#### ----------------------- USING OLD MODEL to predict ----------------------------

### ---------- Loading Prev Model (Main Quantities) ---------------
DDS_OM <- readRDS("./_final/old_model/main_models/DDS_OM.rds")
DY_OM <- readRDS("./_final/old_model/main_models/DY_OM.rds")
MIGT_OM <- readRDS("./_final/old_model/main_models/MIGT_OM.rds")
DFFD_OM <- readRDS("./_final/old_model/main_models/DFFD_OM.rds")

# ------------------ DDST ----------------------------
pred_dds <-predict(DDS_OM$finalModel,
                   s=DDS_OM$bestTune$lambda, 
                   type="response",
                   newx=as.matrix(mdl_dds[,2:49]))

postResample(pred_dds, mdl_dds$totDDS)

mdl_dds %>% ggplot(aes(x=totDDS, y=pred_dds)) + geom_point() + stat_smooth(method = "lm")

#DDS Coefficients 
coef(DDS_OM$finalModel,s=DDS_OM$bestTune$lambda)

finalCoef <- as.matrix(coef(DDS_OM$finalModel,s=DDS_OM$bestTune$lambda))
colnames(finalCoef) <- "totDDS"

# Creating an empty data frame to store all coefficients
all_coef_data <- data.frame()

first_row <- rbind(c(Testbed = "MMSA-shelby", Hazard = "earthquake", Model_Type = "main_model", Model_Name = "totDDS", finalCoef))
all_coef_data <- rbind(all_coef_data, first_row)
colnames(all_coef_data)[5:ncol(coef_data)] <- row.names(finalCoef)

#seperatefile
#Storing them in Wide (column-wise) format
#coef_data <- data.frame()
#coef_data <- rbind(c(Testbed = "MMSA-shelby", Hazard = "earthquake", Model_Type = "main_model", Model_Name = "totDDS", finalCoef))
#colnames(coef_data)[5:ncol(coef_data)] <- row.names(finalCoef)

#cf_file_path <- file.path("./_final/Coefficients/total_DDS.csv")
#write.table(coef_data, cf_file_path , append = TRUE, sep = ",", col.names = TRUE, row.names = FALSE)


barplot(finalCoef[-1, "totDDS"], names.arg = rownames(finalCoef)[-1], 
        col = "blue", main = "DDS Coefficient Values", 
        xlab = "predictors", ylab = "Value", cex.names = 0.65, las = 2)

# ------------------ DYT ----------------------------
pred_dy <-predict(DY_OM$finalModel,
                  s=DY_OM$bestTune$lambda, 
                  type="response",
                  newx=as.matrix(mdl_DY[,2:49]))

postResample(pred_dy, mdl_DY$totDY)

mdl_DY %>% ggplot(aes(x=totDY, y=pred_dy)) + geom_point() + stat_smooth(method = "lm")

#DY Coefficients 
coef(DY_OM$finalModel,s=DY_OM$bestTune$lambda)

# ------------------ MIGT ----------------------------
pred_MIGT <-predict(MIGT_OM$finalModel,
                    s=MIGT_OM$bestTune$lambda, 
                    type="response",
                    newx=as.matrix(mdl_MIGT[,2:49]))

postResample(pred_MIGT, mdl_MIGT$totMIGT)

mdl_MIGT %>% ggplot(aes(x=totMIGT, y=pred_MIGT)) + geom_point() + stat_smooth(method = "lm")

#MIGT Coefficients 
coef(MIGT_OM$finalModel,s=MIGT_OM$bestTune$lambda)

# ------------------ DFFD ----------------------------
pred_DFFD <-predict(DFFD_OM$finalModel,
                    s=DFFD_OM$bestTune$lambda, 
                    type="response",
                    newx=as.matrix(mdl_DFFD[,2:49]))

postResample(pred_DFFD, mdl_DFFD$totDFFD)

mdl_DFFD %>% ggplot(aes(x=totDFFD, y=pred_DFFD)) + geom_point() + stat_smooth() 

apply(mdl_DFFD,2,min)
apply(mdl_DFFD_om,2,min)

mdl_DFFD <- mdl_DFFD %>% dplyr::mutate(totDamage = rowSums(dplyr::select(.,GoodsA:TradeH))) 

## Checking for all the observations that have a total DDS impact when total damage = 0
mdl_DFFD %>% dplyr::select(ID,totDFFD,totDamage,Magnitude,epicenter) %>% filter(totDamage == 0)

#DFFD Coefficients 
coef(DFFD_OM$finalModel,s=DFFD_OM$bestTune$lambda)

finalCoef <- as.matrix(coef(DFFD_OM$finalModel,s=DFFD_OM$bestTune$lambda))
colnames(finalCoef) <- "totDFFD" 

#Storing them in Wide (column-wise) format
coef_data <- data.frame()
coef_data <- rbind(c(Testbed = "MMSA-shelby", Hazard = "earthquake", Model_Type = "main_model", Model_Name = "total_DFFD", finalCoef))

colnames(coef_data)[5:ncol(coef_data)] <- row.names(finalCoef)

cf_file_path <- file.path("./_final/Coefficients/total_DFFD.csv")
write.table(coef_data, cf_file_path , append = TRUE, sep = ",", col.names = TRUE, row.names = FALSE)


### ---------- INDIVIDUAL SECTOR PUMA MODELS ---------------

### -------------- DDS Individual Sectors --------------------------
dds_sectors <- list()
## DDS-individual-sectors
for (i in 2:49) 
{
  file_path <- file.path("./_final/old_model/sector-puma-models/dds-sectors", paste0(colnames(DDST)[i], ".rds"))
  dds_sectors[[i]] <- readRDS(file_path)
  names(dds_sectors)[i] <- colnames(DDST)[i]
}

names(dds_sectors)[1] <- "A_dummy_placeholder" #to make sure the seq for sectors start from index 2 to 49
#dds_sectors <- dds_sectors[order(names(dds_sectors))] #ordering alphabetically

# to store rsqs
rsq_dds <- data.frame()
#all_coef_data <- data.frame()

for (i in 2:49) 
{
  outcomes <- data.frame(ID = as.factor(DDST$ID),
                         outcome = DDST[,i]) #need to change for sector name
  sector_mdl_dds <- SHOCKSval %>% left_join(outcomes, by = "ID") 
  
  pred <-predict(dds_sectors[[i]]$finalModel,
                 s=dds_sectors[[i]]$bestTune$lambda, 
                 type="response",
                 newx=as.matrix(sector_mdl_dds[,2:49]))
  
  pR <- postResample(pred, sector_mdl_dds$outcome)
  
  #row_names <- names(dds_sectors)[i]
  rsq_dds <- rbind(rsq_dds, data.frame(
    Sector = names(dds_sectors)[i],
    RMSE = pR[1],
    Rsquared = pR[2],
    MAE = pR[3]
  ))
  
  #sector_plot <- sector_mdl_dds %>% ggplot(aes(x=outcome, y=pred)) + 
  #geom_point() + stat_smooth(method = "lm") + 
  #labs(x = paste(colnames(DDST)[i]), y = paste("pred_", names(dds_sectors)[i]))
  
  #Save the plot as an image file
  #file_path <- file.path("././_individual_models/models/dds_sectors/dds-sector-puma-img/", paste(names(dds_sectors)[i], ".png"))
  #ggsave(file = file_path, plot = sector_plot, width = 4, height = 6.14)
  
  #DDS Coefficients 
  finalCoef <- as.matrix(coef(dds_sectors[[i]]$finalModel,s=dds_sectors[[i]]$bestTune$lambda))
  colnames(finalCoef) <- paste(names(dds_sectors)[i])
  
  #Storing them in Wide (column-wise) format
  coef_data <- data.frame()
  coef_data <- rbind(c(Testbed = "MMSA-shelby", Hazard = "earthquake", Model_Type = "sectorPuma_model", Model_Name = paste('DDS_', names(dds_sectors)[i]), finalCoef))
  
  colnames(coef_data)[5:ncol(coef_data)] <- row.names(finalCoef)
  all_coef_data <- rbind(all_coef_data, coef_data)
  #cf_file_path <- file.path("./_final/Coefficients/dds-sector-coef", paste("DDS_", names(dds_sectors)[i], ".csv"))
  #write.table(coef_data, cf_file_path , append = TRUE, sep = ",", col.names = TRUE, row.names = FALSE) 
  
}

#save rsq info
write.csv(rsq_df, "rsq_dds-sectors.csv", row.names = FALSE)

cf_file_path <- file.path("./_final/Coefficients/DDS_coefficients.csv")
write.table(all_coef_data, cf_file_path , append = TRUE, sep = ",", col.names = TRUE, row.names = FALSE)


### -------------- DFFD Individual Sectors --------------------------
dffd_sectors <- list()
## DDS-individual-sectors
for (i in 2:73) 
{
  file_path <- file.path("./_final/old_model/sector-puma-models/dffd-sectors", paste0(colnames(DFFDT)[i], ".rds"))
  dffd_sectors[[i]] <- readRDS(file_path)
  names(dffd_sectors)[i] <- colnames(DFFDT)[i]
}

names(dffd_sectors)[1] <- "A_dummy_placeholder" #to make sure the seq for sectors start from index 2 to 49
#dffd_sectors <- dffd_sectors[order(names(dffd_sectors))] #ordering alphabetically

# to store rsqs
#rsq_df <- data.frame(Sector = character(), RMSE = numeric(),Rsquared = numeric(),MAE = numeric())
rsq_dffd <- data.frame()
for (i in 2:73) 
{
  outcomes <- data.frame(ID = as.factor(DFFDT$ID),
                         outcome = DFFDT[,i]) #need to change for sector name
  sector_mdl_dffd <- SHOCKSval %>% left_join(outcomes, by = "ID") 
  
  pred <-predict(dffd_sectors[[i]]$finalModel,
                 s=dffd_sectors[[i]]$bestTune$lambda, 
                 type="response",
                 newx=as.matrix(sector_mdl_dffd[,2:49]))
  
  pR <- postResample(pred, sector_mdl_dffd$outcome) #pred vs the actual sector. Should this be from DFFDT instead of mdl_DFFD?
  
  #row_names <- names(dffd_sectors)[i]
  rsq_dffd <- rbind(rsq_dffd, data.frame(
    Sector = names(dffd_sectors)[i],
    RMSE = pR[1],
    Rsquared = pR[2],
    MAE = pR[3]
  ))
  
  #sector_plot <- sector_mdl_dffd %>% ggplot(aes(x=outcome, y=pred)) + 
  #geom_point() + stat_smooth(method = "lm") + 
  #labs(x = paste(colnames(DFFDT)[i]), y = paste("pred_", names(dffd_sectors)[i]))
  
  #Save the plot as an image file
  #file_path <- file.path("./_individual_models/models/dffd_sectors/dffd-sector-puma-img", paste(names(dffd_sectors)[i], ".png"))
  #ggsave(file = file_path, plot = sector_plot, width = 4, height = 6.14)
  
  #DFFD Coefficients 
  finalCoef <- as.matrix(coef(dffd_sectors[[i]]$finalModel,s=dffd_sectors[[i]]$bestTune$lambda))
  colnames(finalCoef) <- paste(names(dffd_sectors)[i])
  
  #Storing them in Wide (column-wise) format
  coef_data <- data.frame()
  coef_data <- rbind(c(Testbed = "MMSA-shelby", Hazard = "earthquake", Model_Type = "SectorPuma_Model", Model_Name = paste(names(dffd_sectors)[i]), finalCoef))
  
  colnames(coef_data)[5:ncol(coef_data)] <- row.names(finalCoef)
  
  cf_file_path <- file.path("./_final/Coefficients/dffd-sector-coef", paste("DFFD_", names(dffd_sectors)[i], ".csv"))
  write.table(coef_data, cf_file_path , append = TRUE, sep = ",", col.names = TRUE, row.names = FALSE)
}

#save rsq info
write.csv(rsq_df, "rsq_dds-sectors.csv", row.names = FALSE)
