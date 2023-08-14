### Graph showing weekly volume of prescriptions, by prophylaxis intensity
### Kayte Andersen, August 20

library("ggplot2")
library("ggsci")
mydata <- read.csv("/Users/andersen/Documents/Dissertation/3 Anticoagulation using HCA/Data visualization/Weekly volume 04092022.csv")
df <- data.frame(mydata)
print(df)

pdf("eFigure3 04092022.pdf", useDingbats=FALSE)
p <- ggplot(data=df, aes(x=week, y=N, group = ac_exposure, fill = factor(ac_exposure))) +
  ggtitle("Weekly volume, by prophylaxis intensity") +
  geom_bar(stat="identity") + 
  scale_fill_jama(name="Prophylaxis Intensity", labels=c("Standard", "Intermediate")) +
  theme(legend.position="bottom") +
  labs(x=" ", y="Volume of person-periods") +
  scale_x_continuous(breaks = c(1,14,27,40,50), labels = c("March 2020", "June 2020","September 2020","December 2020", "February 2021"))

print(p)
dev.off()

pdf("eFigure3 hundred 04092022.pdf", useDingbats=FALSE)
p2 <- ggplot(data=df, aes(x=week, y=N, group = ac_exposure, fill = factor(ac_exposure))) +
  ggtitle("Weekly volume, by prophylaxis intensity") +
  geom_bar(stat="identity", position="fill") + 
  scale_fill_jama(name="Prophylaxis Intensity", labels=c("Standard", "Intermediate")) +
  theme(legend.position="bottom") +
  labs(x=" ", y="Proportion of person-periods") +
  scale_x_continuous(breaks = c(1,14,27,40,50), labels = c("March 2020", "June 2020","September 2020","December 2020", "February 2021"))

print(p2)
dev.off()
