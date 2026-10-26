# Project STAR: class size and kindergarten test scores

library(lmtest)
library(sandwich)

# Load the data
data("STAR", package = "AER")

# Look at the full dataset
dim(STAR)
table(STAR$stark, useNA = "ifany")

# Keep students with a recorded kindergarten class type
star_k <- STAR[!is.na(STAR$stark), ]

# Use regular classes as the comparison group
star_k$stark <- relevel(star_k$stark, ref = "regular")

# Check the sample
nrow(star_k)

# Check missing test scores
sum(is.na(star_k$readk))
sum(is.na(star_k$mathk))

# Summarize scores
summary(star_k$readk)
summary(star_k$mathk)

# Average scores by class type
tapply(star_k$readk, star_k$stark, mean, na.rm = TRUE)
tapply(star_k$mathk, star_k$stark, mean, na.rm = TRUE)

# Share missing a score in each class type
tapply(is.na(star_k$readk), star_k$stark, mean)
tapply(is.na(star_k$mathk), star_k$stark, mean)


# Student characteristics

table(star_k$stark, star_k$gender, useNA = "ifany")
prop.table(table(star_k$stark, star_k$gender), 1) * 100

table(star_k$stark, star_k$ethnicity, useNA = "ifany")
prop.table(table(star_k$stark, star_k$ethnicity), 1) * 100

# Check missing characteristics
sum(is.na(star_k$gender))
sum(is.na(star_k$ethnicity))

# Create indicators for the balance checks
star_k$female <- as.numeric(star_k$gender == "female")
star_k$afam <- as.numeric(star_k$ethnicity == "afam")

# Compare student characteristics within schools
gender_check <- lm(female ~ stark + schoolidk, data = star_k)
ethnicity_check <- lm(afam ~ stark + schoolidk, data = star_k)

# Show the first three coefficients
coef(summary(gender_check))[1:3, ]
coef(summary(ethnicity_check))[1:3, ]


# Basic test-score models

reading_model <- lm(readk ~ stark, data = star_k)
math_model <- lm(mathk ~ stark, data = star_k)

summary(reading_model)
summary(math_model)


# Add school fixed effects

reading_school <- lm(readk ~ stark + schoolidk, data = star_k)
math_school <- lm(mathk ~ stark + schoolidk, data = star_k)

# Check sample sizes
nobs(reading_school)
nobs(math_school)

# Cluster standard errors by school
reading_se <- vcovCL(reading_school, cluster = ~ schoolidk)
math_se <- vcovCL(math_school, cluster = ~ schoolidk)

# Count schools in each model
reading_schools <- length(unique(model.frame(reading_school)$schoolidk))
math_schools <- length(unique(model.frame(math_school)$schoolidk))

# Get results with clustered standard errors
reading_results <- coeftest(
  reading_school,
  vcov. = reading_se,
  df = reading_schools - 1
)

math_results <- coeftest(
  math_school,
  vcov. = math_se,
  df = math_schools - 1
)

# Show class-type results
reading_results[1:3, ]
math_results[1:3, ]


# Add gender and ethnicity

reading_controls <- lm(
  readk ~ stark + gender + ethnicity + schoolidk,
  data = star_k
)

math_controls <- lm(
  mathk ~ stark + gender + ethnicity + schoolidk,
  data = star_k
)

# Compare the small-class estimates
coef(reading_school)["starksmall"]
coef(reading_controls)["starksmall"]

coef(math_school)["starksmall"]
coef(math_controls)["starksmall"]

# Check sample sizes with and without controls
nobs(reading_school)
nobs(reading_controls)

nobs(math_school)
nobs(math_controls)


# Save results

dir.create("outputs", showWarnings = FALSE)

results <- data.frame(
  outcome = c("Reading", "Reading", "Math", "Math"),
  comparison = c(
    "Small vs regular",
    "Aide vs regular",
    "Small vs regular",
    "Aide vs regular"
  ),
  estimate = c(
    reading_results[2:3, 1],
    math_results[2:3, 1]
  ),
  standard_error = c(
    reading_results[2:3, 2],
    math_results[2:3, 2]
  ),
  p_value = c(
    reading_results[2:3, 4],
    math_results[2:3, 4]
  )
)

write.csv(results, "outputs/first_results.csv", row.names = FALSE)
saveRDS(star_k, "outputs/kindergarten_data.rds")

# Save R and package versions
capture.output(sessionInfo(), file = "outputs/session_info.txt")


# Make a figure for small vs regular classes

estimates <- c(
  coef(reading_school)["starksmall"],
  coef(math_school)["starksmall"]
)

standard_errors <- c(
  sqrt(diag(reading_se))["starksmall"],
  sqrt(diag(math_se))["starksmall"]
)

# Calculate 95% confidence intervals
critical_values <- c(
  qt(0.975, df = reading_schools - 1),
  qt(0.975, df = math_schools - 1)
)

lower <- estimates - critical_values * standard_errors
upper <- estimates + critical_values * standard_errors

# Save the figure
png("outputs/class_size_results.png", width = 900, height = 600)

plot(
  estimates,
  ylim = c(min(0, lower) - 1, max(upper) + 1),
  xaxt = "n",
  xlab = "",
  ylab = "Difference in test score points",
  main = "Small vs. Regular Kindergarten Classes",
  pch = 19,
  col = "steelblue"
)

axis(1, at = 1:2, labels = c("Reading", "Math"))

arrows(
  1:2, lower, 1:2, upper,
  angle = 90,
  code = 3,
  length = 0.08
)

abline(h = 0, lty = 2)

dev.off()

# Check the project folder
getwd()

# Use the same reading sample for both models
reading_sample <- star_k[
  complete.cases(
    star_k$readk,
    star_k$stark,
    star_k$schoolidk,
    star_k$gender,
    star_k$ethnicity
  ),
]

# Reading models with and without controls
reading_same_sample <- lm(
  readk ~ stark + schoolidk,
  data = reading_sample
)

reading_same_controls <- lm(
  readk ~ stark + gender + ethnicity + schoolidk,
  data = reading_sample
)

# Compare small-class estimates
coef(reading_same_sample)["starksmall"]
coef(reading_same_controls)["starksmall"]

nobs(reading_same_sample)
nobs(reading_same_controls)


# Use the same math sample for both models
math_sample <- star_k[
  complete.cases(
    star_k$mathk,
    star_k$stark,
    star_k$schoolidk,
    star_k$gender,
    star_k$ethnicity
  ),
]

# Math models with and without controls
math_same_sample <- lm(
  mathk ~ stark + schoolidk,
  data = math_sample
)

math_same_controls <- lm(
  mathk ~ stark + gender + ethnicity + schoolidk,
  data = math_sample
)

# Compare small-class estimates
coef(math_same_sample)["starksmall"]
coef(math_same_controls)["starksmall"]

nobs(math_same_sample)
nobs(math_same_controls)

# Save the same-sample comparison
control_check <- data.frame(
  outcome = c("Reading", "Math"),
  without_controls = c(
    coef(reading_same_sample)["starksmall"],
    coef(math_same_sample)["starksmall"]
  ),
  with_controls = c(
    coef(reading_same_controls)["starksmall"],
    coef(math_same_controls)["starksmall"]
  ),
  observations = c(
    nobs(reading_same_sample),
    nobs(math_same_sample)
  )
)

write.csv(
  control_check,
  "outputs/control_check.csv",
  row.names = FALSE
)