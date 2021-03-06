# ================================================
# A Short Course on Data Analysis Using R Software
# Wan Nor Arifin
# 
# Poisson Regression
# ================================================

# Preliminaries

## Load libraries
library(epiDisplay)
library(car)

# Simple Poisson regression models

## Count data

### X categorical

# - UKaccident.csv is modified from builtin data Seatbelts
acc = read.csv("UKaccident.csv")
#- driverskilled: number of death
#- law: before seatbelt law = 0, after law = 1
str(acc)
head(acc); tail(acc)
# - some descriptives
tapply(acc$driverskilled, acc$law, sum)  # total death before vs after
table(acc$law)  # num of observations before vs after
# - mean count, manually
11826/107  # 110.5234, count before law
1294/15  # 86.26667, count after law
model.acc = glm(driverskilled ~ law, data = acc, family = poisson)
summary(model.acc)  # significant p based on Wald test
# - to get CI
cbind(coef(model.acc), confint(model.acc))
# - ln(count) = 4.71 - 0.25*LAW
4.71 - 0.25  # = 4.46
exp(4.71)  # 111.0522, count before law
exp(4.46)  # 86.48751, count after law
# - Model fit
poisgof(model.acc)  # fit well, based on chi-square test on the residual deviance
# - Diagnostics
#   - standardized residuals
sr = rstandard(model.acc)
sr[abs(sr) > 1.96]
#   - predicted count vs fitted values
fitted.acc = model.acc$fitted
data.frame(acc, fitted.acc)[names(sr[abs(sr) > 1.96]),]  # look at the discrepancies
# Summary with RR
idr.display(model.acc)  # easier, also view LR test

### X numerical

# - Data from https://stats.idre.ucla.edu/stat/data/poisson_sim.csv
aw = read.csv("poisson_sim.csv")
head(aw); tail(aw)
str(aw)
# - num_awards: The number of awards earned by students at one high school.
# - math: the score on their final exam in math.
model.aw = glm(num_awards ~ math, data = aw, family = poisson)
summary(model.aw)  # math sig.
cbind(coef(model.aw), confint(model.aw))
poisgof(model.aw)  # fit well
sr = rstandard(model.aw)
sr[abs(sr) > 1.96]
aw_ = data.frame(aw[c(4,2)], predicted = model.aw$fitted); head(aw_); tail(aw_)
aw_[names(sr[abs(sr) > 1.96]),] # look at the discrepancies
# 1 unit increase in math score
idr.display(model.aw)
# 10 unit increase in math score? Manually...
b1 = coef(model.aw)[[2]]*10
b1.ll = confint(model.aw)[[2]]*10
b1.ul = confint(model.aw)[[4]]*10
exp(cbind("Math RR" = b1, "95% LL" = b1.ll, "95% UL" = b1.ul))

## Rate data

# - data in Fleiss et al 2003
" Table 12.1
  cigar.day person.yrs cases        rate        pred
1       0.0       1421     0 0.000000000 0.000793326
2       5.2        927     0 0.000000000 0.001170787
3      11.2        988     2 0.002024291 0.001834458
4      15.9        849     2 0.002355713 0.002607843
5      20.4       1567     9 0.005743459 0.003652195
6      27.4       1409    10 0.007097232 0.006167215
7      40.8        556     7 0.012589928 0.016813428
"
cigar.day = c(0, 5.2, 11.2, 15.9, 20.4, 27.4, 40.8)
person.yrs = c(1421, 927, 988, 849, 1567, 1409, 556)
cases = c(0, 0, 2, 2, 9, 10, 7)
cig = data.frame(cigar.day, person.yrs, cases); cig
cig$rate = cig$cases/cig$person.yrs; cig

model.cig = glm(cases ~ cigar.day, offset = log(person.yrs), 
                data = cig, family = "poisson")
# - it includes offset variable
summary(model.cig)
poisgof(model.cig)
cig$pred = model.cig$fitted/cig$person.yrs; cig
idr.display(model.cig)  # interpret?
# - 5 cigar/day
exp(coef(model.cig)[[2]]*5)  # interpret?
# - 10 cigar/day
exp(coef(model.cig)[[2]]*10)  # interpret?

# Multiple Poisson regression model

# - Again, data from https://stats.idre.ucla.edu/stat/data/poisson_sim.csv
aw = read.csv("poisson_sim.csv")
str(aw)
head(aw); tail(aw)
# num_awards: The number of awards earned by students at one high school.
# prog: 1 = General, 2 = Academic, 3 = Vocational
# math: the score on their final exam in math.
# factor prog & save as a new variable prog1
aw$prog1 = factor(aw$prog, levels = 1:3, labels = c("General", "Academic", "Vocational"))
str(aw)
head(aw); tail(aw)

## Univariable

# - Math
model.aw.u1 = glm(num_awards ~ math, data = aw, family = poisson)
summary(model.aw.u1) # Math sig.
# - Prog
model.aw.u2 = glm(num_awards ~ prog1, data = aw, family = poisson)
summary(model.aw.u2) # Vocational vs General not sig. -> Combine
aw$prog2 = recode(aw$prog1, "c('General', 'Vocational') = 'General & Vocational'")
levels(aw$prog2)
# - Prog2: General & Vocational vs Academic
model.aw.u2a = glm(num_awards ~ prog2, data = aw, family = poisson)
summary(model.aw.u2a)
table(No_Award = aw$num_awards, aw$prog2)
tapply(aw$num_awards, aw$prog2, sum)

## Multivariable

model.aw.m1 = glm(num_awards ~ math + prog2, data = aw, family = poisson)
summary(model.aw.m1)  # both vars sig.
poisgof(model.aw.m1)  # good fit
idr.display(model.aw.m1)  
AIC(model.aw.u1, model.aw.u2a, model.aw.m1)
# - diagnostics
sr = rstandard(model.aw.m1)
sr[abs(sr) > 1.96]
aw$pred = model.aw.m1$fitted
aw_diag = data.frame(num_of_awards = aw$num_awards, pred_awards = round(aw$pred, 1))
aw_diag[names(sr[abs(sr) > 1.96]), ] # look at the discrepancies
# - model fit: scaled Pearson chi-square statistic
quasi = summary(glm(num_awards ~ math + prog2, data = aw, family = quasipoisson))
quasi$dispersion  # dispersion parameter = scaled Pearson chi-square statistic
# - closer to 1, better.

## Interaction
model.aw.i1 = glm(num_awards ~ math + prog2 + math*prog2, data = aw, family = poisson)
summary(model.aw.i1)  # interaction term not sig.
AIC(model.aw.m1, model.aw.i1)  # increase in AIC, M1 is better

## Final model
# - Accept model.aw.m1
idr.display(model.aw.m1)
b1 = coef(model.aw.m1)[[2]]*10
b1.ll = confint(model.aw.m1)[[2]]*10
b1.ul = confint(model.aw.m1)[[5]]*10
exp(cbind("Math RR" = b1, "95% LL" = b1.ll, "95% UL" = b1.ul))