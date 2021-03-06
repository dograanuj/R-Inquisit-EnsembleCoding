require(lmerTest)
require(dplyr)
require(tidyr)

rawData <- read.csv("ensemble3_data_clean.csv")
rawDemog <- read.csv("ensemble3_data_demographics.csv")

# Filter data to main results during valid face trials:
cleanData <- rawData %>% 
  filter(blockcode == "gridcompare_block",
         values.trial_retry == 0,
         !is.na(correct_num)) %>%
  select(-trialcode)

# Get quick summary for subjects on # observations and avg. performance ...
# All subjects should have 100 valid trials:
sbjSummary <- group_by(cleanData, subject) %>%
  summarize(
    count = n(),
    mean_correct = mean(correct_num, na.rm = TRUE)
  )

# Do a quick check on subject demographics:
cleanDemog <- group_by(rawDemog, subject) %>%
  summarize(
    age = mean(age_response),
    gender = unique(gender_response)
  )

# Remove subjects who didn't finish the study from data/demog files:
exclSbj <- sbjSummary$subject[sbjSummary$count!=100]
cleanData <- filter(cleanData, !(subject %in% exclSbj))
cleanDemog <- filter(cleanDemog, !(subject %in% exclSbj))
sbjSummary <- filter(sbjSummary, !(subject %in% exclSbj))

####################
### FINAL N = 5000 observations (50 subjects * 100 valid observations):
####################

# Check final subject demographics ...
# M (SD) age = 39.40 (13.55) years; 23 females:
mean(cleanDemog$age); sd(cleanDemog$age)
length(cleanDemog$gender[cleanDemog$gender=="Female"])

# Do quick stats on subject performance ,,,
#     - correct_num = 0 (incorrect) vs. 1 (correct)
#     - grid_sd = standard deviation of 4 grid faces in trust ratings
#     - easiness = absolute value of trust difference between mean(grid faces) 
#          vs. mean(compare face); higher numbers = easier

cleanData$subject <- as.factor(cleanData$subject)
cleanData$grid_sd <- apply(cleanData[,11:14], 1, sd)

# mean of x = 0.6046, t = 10.541, df = 49, p-value = 3.4e-14
t.test(sbjSummary$mean_correct, mu = 0.5)

# Only intercept (significant):
glmer1 <- glmer(correct_num ~ 1 + (1|subject), 
                          family = "binomial",
                          data = cleanData)
summary(glmer1)

# With grid_sd as predictor (not significant):
glmer2 <- glmer(correct_num ~ grid_sd + (1|subject), 
                          family = "binomial",
                          data = cleanData)
summary(glmer2)

# With easiness as predictor (significant):
glmer3 <- glmer(correct_num ~ easiness + (1|subject), 
                          family = "binomial",
                          data = cleanData)
summary(glmer3)


