setwd("/home/tamara/Documents/MATLAB/VSDI/TORus/plot/informes/03_figure_sketch/fast_anova")
#rawdata <-read.csv("long_format_forR.csv") #210521 peak minus baseline
#rawdata <-read.csv("long_format_forR_slopemean210521_400.csv") #210521 peak minus baseline
rawdata <-read.csv("long_format_forR_wmean210521_400datacirc_filt309.csv") #210521 peak minus baseline

tit= "210521: window 0-250ms mean"; # for plots
file= 'RESULTS 210521 mean in window ANOVA 2w AND POST-HOC.txt' # to sink the data in


# Three-way mixed ANOVA: 2 between- and 1 within-subjects factors
# https://www.datanovia.com/en/lessons/mixed-anova-in-r/#three-way-bww-b


# LOAD PACKAGES
library(tidyverse) #for data manipulation and visualization
library(ggpubr) #for creating easily publication ready plots. contains ggqqplot
library(rstatix) #provides pipe-friendly R functions for easy statistical analyses. contains: shapiro_test and levene_test
library("scales")
library (emmeans)
library(car)

# Change 'tibble' options so all columns and rows are printed:
options(tibble.width = Inf)
options(tibble.print_min = Inf)

# LOAD DATA AND RENAME
data <- rawdata[c(1,2,4) ]
# transform into factors
data$value  <-data$data_long1
data$mA <- as.factor(data$data_long2)
data$roi <- as.factor(data$data_long4)

data <- data[c(4,5,6) ]
# If we want a subset
data <- data[data$mA %in% c("0", "0.4"), ] 


library(dplyr)
##datanoc01$EC<- mapvalues(datanoc01$EC, from = c(1, 2), to = c("ECmas", "ECmenos"))
#datanoc01$group<- mapvalues(datanoc01$group, from = c(0, 1, 2), to = c("dm2", "dm3", "som"))
#datanoc01$sesion<- mapvalues(datanoc01$sesion, from = c(1, 2, 3, 4, 5), to = c("hab", "t1", "t2", "t3", "t4"))



#########################################################################
## 2-WAY ANOVA: FORMATED AND SINKING INTO OUTPUT.txt #### 
#########################################################################
library(ggthemes) #https://rafalab.github.io/dsbook/ggplot2.html#add-on-packages

# 1. SUMMARY STATISTICS ####

sink(file)
print(tit)
print("SUMMARY STATISTICS")
print("")
print("Summary grouped by factor ' roi'")
data %>%
  group_by(roi) %>%
  get_summary_stats(value, type = "mean_sd") #value cannot be a factor

print("")
print("Summary grouped by factor 'mA'")
data %>%
  group_by(mA) %>%
  get_summary_stats(value, type = "mean_sd") #value cannot be a factor

print("")
print("Summary grouped by both factors")
data%>%
  group_by(roi,mA) %>%
  get_summary_stats(value, show = c("mean", "sd", "se", "median"))

sink()
# 2. BOXPLOT
# change and save manually:
bxp <- ggboxplot(
  data, x = "roi", y = "value",
  color = "mA", 
  ggtheme = ggthemes::theme_fivethirtyeight(), # choosing a different theme
  package = "wesanderson", # package from which color palette is to be taken
  palette = "Darjeeling1" # choosing a different color palette
  # palette = "jco",
) +
  ggtitle(tit)
bxp


bxp <- ggboxplot(
  data, x = "mA", y = "value",
  color = "roi", 
  ggtheme = ggthemes::theme_fivethirtyeight(), # choosing a different theme
  package = "wesanderson", # package from which color palette is to be taken
  palette = "Darjeeling1" # choosing a different color palette
  # palette = "jco",
) +
  ggtitle(tit)
bxp

#graphics.off()

# 3 . ANOVA: 2-way anova, not repeated measures
sink(file)
sink("test.txt")
knitr::kable(get_anova_table(res.aov), caption = 'ANOVA Table (type III tests) - lo mismo, mas bonito')
sink()

print("ANOVA: ANOVA SUMMARY")
sink()
anova_summary(aov(value ~roi*mA, data=data))
res.aov <- anova_test(data=data, formula = value ~roi*mA, # + Error(model)
                      #error function: we want to control for that between-participant variation over all of our within-subjects variables.
                      effect.size='pes', type=3)

print("ANOVA: ANOVA TABLE")
get_anova_table(res.aov)
knitr::kable(get_anova_table(res.aov), caption = 'ANOVA Table (type III tests) - lo mismo, mas bonito')

print("Complete ANOVA object to check Mauchly and Sphericity corrections") --???
res.aov  

# 4. POST-HOC ANALYSIS

print("POST-HOC with Bonferroni adjustment")

# 4.1: PAIRWISE COMPARISONS each level of the within-s factors

# 4.1.1. Each level of block
# Paired t-test is used because we have repeated measures by time


print("POST-HOC: PAIRWISE COMPARISONS BETWEEN ROI LEVELS  (non paired)")
pwc1 <- data %>%
  group_by(roi) %>%
  pairwise_t_test(
    formula = value ~ mA, paired = FALSE, 
    p.adjust.method = "bonferroni"
  )
#  %>% select(-df, -statistic, -p) # Remove details
pwc1

knitr::kable(pwc1, caption = 'POST-HOC: PAIRWISE COMPARISONS BETWEEN ROI LEVELS')


print("POST-HOC: PAIRWISE COMPARISONS BETWEEN mA LEVELS (non paired)")
# non-pair to compare EC? because is not a rm?
pwc2 <- data %>%
  group_by(mA) %>%
  pairwise_t_test(
    formula = value ~ roi, paired = FALSE, 
    p.adjust.method = "bonferroni"
  )
#%>%   select(-df, -statistic, -p) # Remove details
pwc2

knitr::kable(pwc2, caption = 'POST-HOC: PAIRWISE COMPARISONS BETWEEN mA LEVELS')

sink ()



# 5. TEST ASSUMPTIONS  ####

# 5.1: PRESENCE OF OUTLIERS 

print("ASSUMPTIONS: PRESENCE OF OUTLIERS")
data %>%
  group_by(roi, mA) %>%
  identify_outliers(value)

data %>%
  group_by(mA) %>%
  identify_outliers(value)


# 5.2: NORMALITY ASSUMPTION
# The normality assumption can be checked by computing Shapiro-Wilk test for each time point.
# p > 0.05: normal distribution (H0)

print("ASSUMPTIONS: NORMALITY - SHAPIRO-WILK TEST")
data %>%
  group_by(roi, mA) %>%
  shapiro_test(value)

# CREATE QQ plot for each cell of design: (for bigger sample sizes)
#ggqqplot(dm2, "brady", ggtheme = theme_bw()) +
#facet_grid(block ~ EC, labeller = "label_both")
#If all the points fall approx. along the ref.line, for each cell, we can assume normality of the data.


# 5.3. HOMOCEDASTICITY: not needed (not between subjects comparisons)

# 5.4: SPERICITY ASSUMPTION: done and corrected internally by the functions anova_test() and get_anova_table()
# Sphericity is an important assumption of a repeated-measures ANOVA 

print("ASSUMPTIONS: SPERICITY ASSUMPTION is performed and applied internally")

# 5.5 : HOMOGENEITY OF  COVARIANCES  !!! sale diferente
print("ASSUMPTIONS: EQUALITY OF COVARIANCEs - Box's Text")
box_m(data[, "value", drop = FALSE], data$roi)
# The assumption of homogeneity of variance is an assumption of the independent samples t-test and ANOVA stating
#that all comparison groups have the same variance.  The independent samples t-test and ANOVA utilize the t and F statistics respectively,
# which are generally robust to violations of the assumption as long as group sizes are equal
sink()

#######################################3

# BOXPLOT
bxp <- ggboxplot(
  data, x = "mA", y = "value",
  color = "roi", palette = c("jco"),
  #facet.by =  "mA"
  title =tit 
)
bxp

bxp <- ggboxplot(
  data, x = "roi", y = "value",
  color = "mA", palette = c("jco"),
  title =tit 
  
)
bxp

# CHECK ASSUMPTIONS

# A1: OUTLIERS
data %>%
  group_by(roi, mA) %>%
  identify_outliers(value)


# A2: NORMALITY ASSUMPTION
data %>%
  group_by(roi, mA) %>%
  shapiro_test(value)
# p < 0.05: non-normal distribution

# CREATE QQ plot for each cell of design:
ggqqplot(data, "value", ggtheme = theme_bw()) +
  facet_grid(mA ~ roi, labeller = "label_both")

# Create QQ plot for each cell of design:
ggqqplot(data, "value", ggtheme = theme_bw()) +
  facet_grid(roi~mA , labeller = "label_both")

#facet_grid(EC+group ~ sesion, labeller = "label_both")

#If all the points fall approx. along the ref.line, for each cell, we can assume normality of the data.

# A3: HOMOGENEITY OF VARIANCE ASSUMPTION (Levene's test at each level of the within-subjects factor)
data %>%
  group_by(roi) %>%
  levene_test(value ~ mA)

data %>%
  group_by(mA) %>%
  levene_test(value ~ roi)

# Note that, if you do not have homogeneity of variances, you can try to transform the outcome (dependent) variable to correct for the unequal variances.
# If group sample sizes are (approximately) equal, run the three-way mixed ANOVA anyway because it is somewhat robust to heterogeneity of variance in these circumstances.
# It's also possible to perform robust ANOVA test using the WRS2 R package.'''


# A4: SPERICITY ASSUMPTION: done and corrected internally by the functions anova_test() and get_anova_table()

# COMPUTATION OF ANOVA
#anova_summary(aov(value ~ roi*mA + Error(idx/(mA)), data=data))
anova_summary(aov(value ~ roi*mA, data=data))

# TWO-WAY ANOVA
res.aov <- anova_test(data = data, dv = value,
  between = roi, within = mA)

get_anova_table(res.aov)

# extracted from inside: wid = idx,

# COMPUTATION ONE WAY FOR mA
model <- lm(value ~ mA*roi, data = data)
# effect on each level of mA
data %>%
  group_by(roi) %>%
  anova_test(value ~ mA, error = model)
# effect on each level of roi
data %>%
  group_by(mA) %>%
  anova_test(value ~ roi, error = model)

# TWO-WAY ANOVA
anova_2way <- aov(value~roi*mA, data = data)
summary(anova_2way)

get_anova_table(anova_2way)
## Contrasts set to contr.sum for the following variables: Btw_Cond
knitr::kable(nice(anova_2way)) ##call for formatted ANOVA table using knitr

# summary
require("dplyr")
group_by(data, roi, mA) %>%
  summarise(
    count = n(),
    mean = mean(value, na.rm = TRUE),
    sd = sd(value, na.rm = TRUE)
  )
# POST-HOC
# Using Turkey
TukeyHSD(anova_2way, which = c("roi" , "mA"))


##Main effects
mixed_fitted_roi<-emmeans(anova_2way, ~roi)
mixed_fitted_roi

mixed_fitted_mA<-emmeans(anova_2way, ~mA)
mixed_fitted_mA


mixed_fitted_interactions1 <-emmeans(anova_2way, ~roi|mA)
mixed_fitted_interactions1
pairs(mixed_fitted_interactions1)


##pairwise comparison with no correction.
pairs(mixed_fitted_interactions1)

# LEVENE TEST
test_levene(anova_2way) #lawstat package


# 6. PLOT

# OLD VISUALIZATION : VISUALIZATION: BOXPLOT WITH p-values (not working - because it's two way???)

# visualizacion grouped by mA
pwc1 <- pwc1%>% add_xy_position(x = "mA")

bxp <- ggboxplot(
  data, x = "mA", y = "value",
  color = "roi", 
  ggtheme = ggthemes::theme_fivethirtyeight(), # choosing a different theme
  package = "wesanderson", # package from which color palette is to be taken
  palette = "Darjeeling1" # choosing a different color palette
  # palette = "jco",
) +
  ggtitle('anova result')+
  
  stat_pvalue_manual(pwc1, tip.length = 0, hide.ns = TRUE)+
  labs(
    subtitle = get_test_label(pwc1, detailed = TRUE),
    caption = get_pwc_label(pwc1)
  )
bxp




# link: https://rpkgs.datanovia.com/rstatix/reference/anova_test.html#details
