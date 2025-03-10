library(tidyverse)
library(fixest)
library(skimr)

# load data
ab_data <-
  read_csv(
    "data/ab_data.csv",
    col_select = c("EMP", "WAGE", "W", "N", "K", "YS", "ID", "YEAR", "IND")
  )

# data overview
skim(ab_data)

# Scatterplot of W on N
pl1 <-
  ggplot(ab_data, aes(x = EMP, y = WAGE)) +
  geom_point() +
  geom_smooth(method = "lm", formula = y ~ x, se = FALSE) +
  labs(
    x = "Employment",
    y = "Wages"
  ) +
  theme_minimal()

pl1

ggsave(
  filename = "outputs/pl1.png",
  bg = "white",
  width = 14,
  height = 10,
  unit = "cm"
)

# conventional significance stars
setFixest_etable(
  style.df = style.df(
    signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10)
  ),
  se.below = TRUE
)

# easy to read variable names
setFixest_dict(
  dict = c(
    EMP = "Employment",
    WAGE = "Wage",
    W = "Log wage",
    N = "Log employment",
    K = "Log capital",
    YS = "log industry output",
    ID = "Firm",
    YEAR = "Year",
    IND = "Industry"
  )
)

# baseline regression
est1 <-
  feols(
    W ~ N + K + YS | ID + YEAR,
    data = ab_data,
    cluster = ~ID
  )

res1 <- etable(est1)
res1

res1 %>% write_csv("outputs/res1.csv")


# sensitivity to fixed effects specifications
est2 <-
  feols(
    W ~ N + K + YS | csw0(ID, YEAR),
    data = ab_data
  )
etable(est2)

# heterogeneity analysis via subsamples

est3 <-
  feols(
    W ~ N + K + YS | ID + YEAR,
    data = ab_data,
    cluster = ~ID,
    split = ~IND
  )

etable(est3)

# robustness - subset sample for firms in 1980s

est4 <-
  feols(
    W ~ N + K + YS | ID + YEAR,
    data = ab_data,
    cluster = ~ID,
    subset = ~ YEAR >= 1980
  )
etable(est4)
