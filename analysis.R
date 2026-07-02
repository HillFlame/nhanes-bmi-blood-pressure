# =============================================================
# BMI and Systolic Blood Pressure in US Adults (NHANES 2017-2018)
# Self-directed data-analysis project
#
# Question: Is higher BMI associated with higher systolic blood
# pressure in US adults, and persisting after adjusting for age 
# and sex?
#
# Data: NHANES 2017-2018 ("J" cycle), CDC public survey data,
# pulled from CDC via the nhanesA package.
# =============================================================

# ---- Packages ----
library(tidyverse)   
library(nhanesA)     

demo <- nhanes("DEMO_J")
bmx  <- nhanes("BMX_J")
bpx  <- nhanes("BPX_J")

# ----
demo_mini <- demo |>
  select(SEQN, gender = RIAGENDR, age = RIDAGEYR)

bmx_mini <- bmx |>
  select(SEQN, bmi = BMXBMI)

bp_mini <- bpx |>
  transmute(
    SEQN,
    sys = round(rowMeans(pick(BPXSY1, BPXSY2, BPXSY3, BPXSY4), na.rm = TRUE))
  )

# ---- Merge tables ----
analysis <- bp_mini |>
  left_join(bmx_mini,  by = "SEQN") |>
  left_join(demo_mini, by = "SEQN") |>
  relocate(gender, age, bmi, sys, .after = SEQN)


analysis <- analysis |>
  filter(age >= 18) |>
  drop_na(sys, bmi, age, gender)


analysis <- analysis |>
  mutate(gender = factor(gender, levels = c("Male", "Female")))

nrow(analysis)   # final analytic sample (~5,179)

# ---- Regression models ----
model_simple <- lm(sys ~ bmi, data = analysis)
summary(model_simple)

model_adjusted <- lm(sys ~ bmi + age + gender, data = analysis)
summary(model_adjusted)

# ---- Figures ----
dir.create("figures", showWarnings = FALSE)

fig1 <- ggplot(analysis, aes(x = bmi, y = sys)) +
  geom_point(alpha = 0.4) +
  geom_smooth(method = "lm", color = "black") +
  labs(
    title    = "BMI and systolic blood pressure in US adults",
    subtitle = "NHANES 2017-2018",
    x = "Body Mass Index (kg/m^2)",
    y = "Systolic Blood Pressure (mmHg)"
  )

ggsave("figures/bmi_vs_systolic.png", fig1,
       width = 7, height = 5, dpi = 300)

fig2 <- ggplot(analysis, aes(x = bmi, y = sys)) +
  geom_point(aes(color = age), alpha = 0.5) +
  geom_smooth(method = "lm", color = "black") +
  scale_color_viridis_c() +
  labs(
    title    = "BMI and systolic blood pressure, colored by age",
    subtitle = "NHANES 2017-2018",
    x = "Body Mass Index (kg/m^2)",
    y = "Systolic Blood Pressure (mmHg)",
    color = "Age (years)"
  )

ggsave("figures/bmi_vs_systolic_by_age.png", fig2,
       width = 7, height = 5, dpi = 300)
