library(dplyr)
library(tidyr)
library(ggplot2)
library(lubridate)
library(caret)
library(DAAG)
library(forecast)
library(TTR)

# remember sql/dplyr is lazy evaluation until 
VZCollision <- tbl(src_sqlite(path='VisionZeroDB.sqlite'),'VZCollision')
tidy.VZ <- VZCollision %>% 
  select(Date, PersonsInjured) %>%
  filter(PersonsInjured > 0) %>% 
  group_by(Date) %>%
  summarise(Total.Counts = n())
tidy.VZ2 <- collect(tidy.VZ)

tidy.VZ2$Date <- as.Date(tidy.VZ2$Date, '%m/%d/%Y')
tidy.VZ2 <- arrange(data.frame(tidy.VZ2), Date)

ggplot(data = tidy.VZ2, aes(x = Date, y = Total.Counts)) + geom_line() + geom_smooth(method = lm)

lmfit <- lm(tidy.VZ2$Total.Counts ~ tidy.VZ2$Date)
lmfit

t.test(row_number(tidy.VZ2$Date), tidy.VZ2$Total.Counts)
# p-value < 0.05 Date affects total counts, due to seasonality

tidy.VZ3 <- tidy.VZ2 %>% mutate(Year = year(tidy.VZ2$Date), Month = month(tidy.VZ2$Date),
                               Week = week(tidy.VZ2$Date), Day = day(tidy.VZ2$Date),
                               Wday = wday(tidy.VZ2$Date)) %>% ungroup()

Injuries.By.Year <- tidy.VZ3 %>%
  group_by(Year) %>%
  summarise(Total.Counts = sum(Total.Counts))
t.test(row_number(Injuries.By.Year$Year[2:4]), Injuries.By.Year$Total.Counts[2:4])

Injuries.By.Month.Year <- tidy.VZ3 %>%
  group_by(Month, Year) %>%
  summarise(Total.Counts = sum(Total.Counts))

ggplot(data = Injuries.By.Month.Year, aes(x= Month, y = Total.Counts, color = as.factor(Year))) + 
  geom_line()

# Multi Variate linear regression
dataPartition <- as.integer(.9*length(tidy.VZ3$Total.Counts))
df_train <- tidy.VZ3[ 1:dataPartition,]
df_test  <- tidy.VZ3[-(1:dataPartition),]

fit.mvlm <- lm(data = df_train, Total.Counts~ Year * Date * (sin(2*pi*Day/31) + cos(2*pi*Day/31)) * 
                 (sin(2*pi*Month/12) + cos(2*pi*Month/12)) * (sin(2*pi*Week/52) + cos(2*pi*Week/52)) *
                 (sin(2*pi*Wday/7) + cos(2*pi*Wday/7)))
summary(fit.mvlm)

ggplot() + geom_point(data = tidy.VZ3, aes(x = Date, y = Total.Counts)) + 
  geom_line(data = fit.mvlm, aes(x = tidy.VZ3$Date[1:dataPartition], y = fit.mvlm$fitted.values), color = 'red') +
  geom_line(aes(x = tidy.VZ3$Date[-(1:dataPartition)], y = predict.lm(fit.mvlm, df_test)), color = 'green')


cvfit <- cv.lm(data = df_train, form.lm = Total.Counts~ Year * Date * (sin(2*pi*Day/31) + cos(2*pi*Day/31)) * 
        (sin(2*pi*Month/12) + cos(2*pi*Month/12)) * (sin(2*pi*Week/52) + cos(2*pi*Week/52)), m = 10)

cvfit$cvpred

ggplot() + geom_point(data = tidy.VZ3, aes(x = Date, y = Total.Counts)) + 
  geom_line(data = fit.mvlm, aes(x = tidy.VZ3$Date[1:dataPartition], y = cvfit$cvpred), color = 'red') +
  geom_line(aes(x = tidy.VZ3$Date[-(1:dataPartition)], y = predict.lm(cvfit, df_test)), color = 'green')

# Time series analysis

tsTC <- ts(tidy.VZ3$Total.Counts, frequency = 365, start=c(2012, 7))
TCComp <- decompose(tsTC)
plot(TCComp)
# remove seasonal
TCSeaAdj <- tsTC-TCComp$seasonal

tidy.VZ3$TotalCountsSMA50 <- SMA(tidy.VZ3$Total.Counts, n=50)
ggplot() + geom_point(data = tidy.VZ3, aes(x = Date, y = Total.Counts)) + 
  geom_line(data = tidy.VZ3, aes(x = Date, y = TotalCountsSMA50), color = 'green')

TCForecasts <- HoltWinters(tsTC)
TCForecasts
plot(TCForecasts)
TCFutForecasts <- forecast.HoltWinters(TCForecasts, h = 365)
plot.forecast(TCFutForecasts)

# 
# # RFE =================
# model.matrix(~Total.Counts, df_train)
# dv <- dummyVars(Total.Counts~(Date+sin(2*3.14*Day/31)+cos(2*3.14*Day/31)+
#                             sin(2*3.14*Week/52)+cos(2*3.14*Week/52))^2
#             , data = as.data.frame(df_train))
# df_train_new <- predict(dv, df_train)   
# dim(df_train_new)
# #test the following 
# subsets <- c(1:5, 10, 15, 20)
# #The simulation will fit models with subset sizes of 25, 20, 15, 10, 5, 4, 3, 2, 1.
# 
# set.seed(12)
# highlyCorDescr  <- findCorrelation(cor(df_train_new), 
#                                    cutoff = .7, verbose = TRUE)
# df_train_new <- df_train_new[,-highlyCorDescr]
# df_test <- df_test[,-highlyCorDescr]
# 
# comboInfo <- findLinearCombos(df_train_new)
# comboInfo
# 
# ctrl <- rfeControl(functions = lmFuncs,
#                    method = "cv",
#                    number = 5,
#                    # metric = c(internal = "ROC", external = "ROC"),
#                    metric = 'RMSE',
#                    repeats = 5,
#                    classProbs = TRUE,
#                    verbose = TRUE)
# 
# lmProfile <- rfe(x = df_train_new, y = df_train$Total.Counts,
#                  sizes = subsets,
#                  rfeControl = ctrl)
# 
# lmProfile
# predictors(lmProfile)
# #plot
# trellis.par.set(caretTheme())
# plot(lmProfile, type = c("g", "o"))
# 
# # Now we can use only chosen predictors to do lm
# 
# train_data <- cbind(data_62_train, data_1_train$N)
# names(train_data)[ncol(train_data)] <- "N" 
# Fit_test <- lm(N ~ ., data = train_data)
# summary(Fit_test)
