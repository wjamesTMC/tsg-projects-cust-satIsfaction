##############################################################################
#
# Customer Sat data Analysis Project - Comments section
# Bill James / jamesw@csps.com
#
# Files:  https://github.com/wjamesTMC/tsg-projects-2019_05-cust-sat.git
#
##############################################################################

#
# Library setups
#

# Import libraries
library(tidyverse)
library(tidyr)
library(plyr)
library(dplyr)
library(caret)
library(ggplot2)
library(ggthemes)
library(extrafont)
library(scales)
library(reshape2)
library(stringi)
library(expss)
library(grid)
library(gridExtra)
library(lattice)
library(janitor)
library(rmarkdown)
library(kableExtra)

#--------------------------------------------------------------------
#
# File open, cleanup, and set up for the analysis
#
#--------------------------------------------------------------------

#
# Download and open survey file
#


# Import and Open the data file / Establish the data set
data_filename <- "0_Input_CustSatEmailTest.csv"
data_filename <- "0_Input_CustSatExcerptTest.csv"
wkgdat <- read.csv(data_filename, stringsAsFactors = FALSE)

vocab_filename <- "0_Input_Vocabulary.csv"
comms          <- read.csv(vocab_filename, stringsAsFactors = FALSE)
pos_vocab      <- comms %>% filter(Tone == "P")
neg_vocab      <- comms %>% filter(Tone == "N")

# Calc the number of comments
num_comments <- length(unique(wkgdat$Comments))

#--------------------------------------------------------------------
#
# Vocabulary analysis - Cumulative
#
#--------------------------------------------------------------------

#
# Positive vocabulary elements
#

# Build dataframe for positives
pos_df   <- data.frame(Word  = pos_vocab$Term,
                       Count = 1:nrow(pos_vocab),
                       Type  = "P")

# Loop to identify positive words in the comments field
pct <- 0
for(i in 1:nrow(pos_vocab)) {
  x <- str_detect(wkgdat$Comments, pos_vocab$Term[i])
  pos_df[i, 2] <- length(x[x == TRUE])
  pct <- pct + length(x[x == TRUE])
}

# Remove words with zero counts
pos_df  <- pos_df %>% filter(Count != 0)

# Sort from high to low
pos_df <- arrange(pos_df, desc(Count), Word)

# Print out the top 10 words
pos_df[1:10, ]

#
# Negative vocabulay elements
#

# Build dataframe for negatives
neg_df   <- data.frame(Word  = neg_vocab$Term,
                       Count = 1:nrow(neg_vocab),
                       Type  = "N")


# Loop to identify negative words in the comments field
nct <- 0
for(i in 1:nrow(neg_vocab)) {
  x <- str_detect(wkgdat$Comments, neg_vocab$Term[i])
  neg_df[i, 2] <- length(x[x == TRUE])
  nct <- nct + length(x[x == TRUE])
}

# Remove words with zero counts
neg_df   <- neg_df %>% filter(Count != 0)

# Sort from high to low
neg_df <- arrange(neg_df, desc(Count), Word)

# Print out the top 10 words
neg_df[1:10, ]

# Create datafrane and append negatives
cum_count_df <- pos_df
cum_count_df <- rbind(cum_count_df, neg_df)

# Determine overall positive and negative indexes (pos / neg words / comments
pos_index <- sum(pos_df$Count) / num_comments
neg_index <- sum(neg_df$Count) / num_comments

# Create a filename and write out the results
filename <- paste("0_Output_email_test",".csv")
filename <- stri_replace_all_fixed(filename, " ", "")
write.csv(cum_count_df, file = filename)

cat("Number of survey responses      :", nrow(wkgdat), "\n",
    "Number of survey comments       :", num_comments, "\n",
    "Comments to responses ratio     :", num_comments / nrow(wkgdat), "\n",
    "Number of positive words        :", pct, "\n",
    "Positive words to comments ratio:", pos_index, "\n",
    "Number of negative words        :", nct, "\n",
    "Negative words to comments ratio:", neg_index, "\n")

# Display results and statistics
cat("Vocabulary word counts / occurrences")
# kable(pos_df) %>%
#   kable_styling(bootstrap_options = "striped", full_width = F, position = "left")

# kable(neg_df) %>%
#   kable_styling(bootstrap_options = "striped", full_width = F, position = "left")

pos_df
neg_df

#--------------------------------------------------------------------
#
# Vocabulary analysis - by Survey
# 
#--------------------------------------------------------------------

# Set the number of surveys 
survey_num <- length(unique(wkgdat$Surveyed))

# Dataframe to collect all the data and calculations
survey_inf <- data.frame(Survey        = survey_num,
                         num_resps     = survey_num,
                         num_comments  = survey_num,
                         c_to_r_ratio  = survey_num,
                         num_pos_words = survey_num,
                         pw_to_c_ratio = survey_num,
                         num_neg_words = survey_num,
                         nw_to_c_ratio = survey_num)

# Loop to examine each survey and assign values to a dataframe
for(i in 1:survey_num) {
  
  #
  # Positive vocabulary elements
  #
  
  # Build dataframe
  sur_pos_df <- data.frame(Survey = unique(wkgdat$Surveyed)[i],
                           Word   = pos_vocab$Term,
                           Count  = 0,
                           Type   = "P")
  
  # Set the specific survey data
  survey_dat  <- wkgdat %>% filter(Surveyed == unique(wkgdat$Surveyed)[i])
  survey_comments <- length(unique(survey_dat$Comments))
  
  # Loop to count the occurrences of positive words
  pct <- 0
  for(j in 1:nrow(pos_vocab)) {
     x <- str_detect(survey_dat$Comments, pos_vocab$Term[j])
     sur_pos_df[j, 3] <- length(x[x == TRUE])
     pct <- pct + length(x[x == TRUE])
  }

  # Remove words with zero counts
  sur_pos_df  <- sur_pos_df %>% filter(Count != 0)
  
  # Sort from high to low
  sur_pos_df <- arrange(sur_pos_df, desc(Count), Word)
  sur_pos_df
  
  #
  # Negative vocabulary elements
  #

  # Build dataframe
  sur_neg_df <- data.frame(Survey = unique(wkgdat$Surveyed)[i],
                           Word   = neg_vocab$Term,
                           Count  = 0,
                           Type   = "N")
  
  # Loop to count the occurrences of negative words
  nct <- 0
  for(j in 1:nrow(neg_vocab)) {
    x <- str_detect(survey_dat$Comments, neg_vocab$Term[j])
    sur_neg_df[j, 3] <- length(x[x == TRUE])
    nct <- nct + length(x[x == TRUE])
  }

  # Remove words with zero counts
  sur_neg_df  <- sur_neg_df %>% filter(Count != 0)
  
  # Sort from high to low
  sur_neg_df <- arrange(sur_neg_df, desc(Count), Word)
  sur_neg_df
  
  # Create combined dataframe
  sur_cum_df <- sur_pos_df
  
  # Append to the cumulative dataframe
  sur_cum_df <- rbind(sur_cum_df, sur_neg_df)
  
  # Create the unique filename by survey and write out the results
  filename <- paste("0_Output_", sur_cum_df[i,1],".csv")
  filename <- stri_replace_all_fixed(filename, " ", "")
  write.csv(sur_cum_df, file = filename)
  
  #
  # Print results of individual surveys
  #
  
  #kable(sur_cum_df) %>%
  #  kable_styling(bootstrap_options = "striped", full_width = F, position = "left")
  
  # Populate summary dataframe
  survey_inf[i, 1] <- unique(wkgdat$Surveyed)[i]
  survey_inf[i, 2] <- nrow(survey_dat)
  survey_inf[i, 3] <- survey_comments
  survey_inf[i, 4] <- round(survey_comments / nrow(survey_dat), digits = 2)
  survey_inf[i, 5] <- pct
  survey_inf[i, 6] <- round(pct / survey_comments, digits = 2)
  survey_inf[i, 7] <- nct
  survey_inf[i, 8] <- round(nct / survey_comments, digits = 2)
    
  # Display results and statistics
  cat("Results for", survey_inf[i, 1], "\n")
  cat("Number of responses             :", survey_inf[i, 2], "\n")
  cat("Number of comments              :", survey_inf[i, 3], "\n")
  cat("Comments to responses ratio     :", survey_inf[i, 4], "\n")
  cat("Number of positive words        :", survey_inf[i, 5], "\n")
  cat("Positive words to comments ratio:", survey_inf[i, 6], "\n")
  cat("Number of negative words        :", survey_inf[i, 7], "\n")
  cat("Negative words to comments ratio:", survey_inf[i, 8], "\n")
  cat("\n")
  
}

survey_inf

#--------------------------------------------------------------------
#
# Build graphics from summary dataframe
#
#--------------------------------------------------------------------

# Number of coments and responses by survey
num_c_and_r <- ggplot() +
  geom_line(data=survey_inf, aes(x=Survey, y=num_resps, color = "Responses"), group=1, size=2) +
  geom_line(data=survey_inf, aes(x=Survey, y=num_comments, color = "Comments"), group=1, size=2) +
  scale_colour_manual("", 
                      breaks = c("Responses", "Comments"),
                      values = c("#0072B2", "#CC0000")) +
  labs(title = "Count of Comments and Responses", subtitle = "Numbers of each by Survey") + ylab("Number") +
  theme(legend.position = c(0.18,0.85))

# Ratio of comments to responses
ratio_c_to_r <- ggplot() +
  geom_line(data=survey_inf, aes(x=Survey, y=c_to_r_ratio, color = "Ratios", group=1), size=2) +
  scale_colour_manual("", breaks = c("Ratios"), values = c("#000099")) +
  labs(title = "Ratio of Comments to Responses", subtitle = "Ratio By Survey") + ylab("Proportion of Comments") +
  theme(legend.position = c(0.15,0.88))

# Arrange the two plots for pasting into deck
grid.arrange(num_c_and_r, ratio_c_to_r, ncol = 2)

# Positive words vs. comments
pw_vs_c <- ggplot() +
  geom_line(data=survey_inf, aes(x=Survey, y=num_pos_words, color = "Positive Words", group=1), size=2) +
  geom_line(data=survey_inf, aes(x=Survey, y=num_comments, color = "Comments", group=1), size=2) +
  scale_y_continuous(limits=c(0, 60)) +
  scale_colour_manual("", 
                      breaks = c("Positive Words", "Comments"),
                      values = c("#0072B2", "#CC0000")) +
  labs(title = "Positive Words vs. Comments", subtitle = "Number of each by Survey") + ylab("Number of Each") +
  theme(legend.position = c(0.2,0.85))

# Negative words vs. comments
nw_vs_c <- ggplot() +
  geom_line(data=survey_inf, aes(x=Survey, y=num_neg_words, color = "Negative Words", group=1), size=2) +
  geom_line(data=survey_inf, aes(x=Survey, y=num_comments, color = "Comments", group=1), size=2) +
  scale_y_continuous(limits=c(0, 60)) +
  scale_colour_manual("", 
                      breaks = c("Negative Words", "Comments"),
                      values = c("#0072B2", "#CC0000")) +
  labs(title = "Negative Words vs. Comments", subtitle = "Number of each by Survey") + ylab("Number of Each") +
  theme(legend.position = c(0.22,0.85))

# Arrange the two plots for pasting into deck
grid.arrange(pw_vs_c, nw_vs_c, ncol = 2)

# Positive and negative words to comments ratios
p_vs_n <- ggplot() +
  geom_line(data=survey_inf, aes(x=Survey, y=pw_to_c_ratio, color = "Positive", group=1), size=2) +
  geom_line(data=survey_inf, aes(x=Survey, y=nw_to_c_ratio, color = "Negative", group=1), size=2) +
  scale_colour_manual("", 
                      breaks = c("Positive Words", "Negative Words"),
                      values = c("#0072B2", "#CC0000")) +
  labs(title = "Ratios of Positive & Negative Words to Comments", subtitle = "Ratio Comparisons by Survey") +
  ylab("# Words / # Comments") +
  theme(legend.position = c(0.22,0.85))

# Arrange the two plots for pasting into deck
grid.arrange(p_vs_n, ncol = 2)


#--------------------------------------------------------------------
#
# End
#
#--------------------------------------------------------------------


