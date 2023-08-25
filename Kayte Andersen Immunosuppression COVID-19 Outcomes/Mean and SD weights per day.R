### Graph showing mean stabilized inverse probability of treatment weights
### Kayte Andersen, October 7

setwd("/Users/andersen/Dropbox (Personal)/PhD Pharmacoepi/Dissertation/3 Anticoagulation using HCA/Data visualization")

library("ggplot2")
#install.packages("ggsci")
library("ggsci")
mean <- read.csv("/Users/andersen/Dropbox (Personal)/PhD Pharmacoepi/Dissertation/3 Anticoagulation using HCA/Data visualization/Means_SD.csv")
mean_df <- data.frame(mean)
print(mean_df)

m <- ggplot(data=mean_df, aes(x=t, y=Means)) +
  ggtitle("Mean of Stabilized Inverse Probability of Treatment Weights \n by Follow-Up Day") +
  geom_point() + 
  theme_minimal() +
  ylim(0, 2) +
  scale_x_continuous(breaks=c(7,14,21)) +
  labs(x="Days since first prophylactic dose", y="Mean trimmed stabilized \n inverse probability of treatment weight")

m


sd <- ggplot(data=mean_df, aes(x=t, y=Means)) +
  ggtitle("Means and Standard Deviations \nof Trimmed Stabilized Inverse Probability of Treatment Weights \nby Follow-Up Day") +
  geom_point() + 
  theme_minimal() +
  geom_errorbar(aes(ymin=Means-sd, ymax=Means+sd), width=.2) +
  ylim(0,2) +
  scale_x_continuous(breaks=c(7,14,21)) +
  labs(x="Days since first prophylactic dose", y="Mean trimmed stabilized \n inverse probability of treatment weight")

sd