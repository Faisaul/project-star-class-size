# Check missing test scores by class type

library(lmtest)
library(sandwich)

# Load the kindergarten data saved by script 01
star_k <- readRDS("outputs/kindergarten_data.rds")

# Create indicators: 1 = missing, 0 = available
star_k$reading_missing <- as.numeric(is.na(star_k$readk))
star_k$math_missing <- as.numeric(is.na(star_k$mathk))

# Compare missing scores within schools
reading_missing_model <- lm(
  reading_missing ~ stark + schoolidk,
  data = star_k
)

math_missing_model <- lm(
  math_missing ~ stark + schoolidk,
  data = star_k
)

# Cluster standard errors by school
reading_missing_se <- vcovCL(
  reading_missing_model,
  cluster = ~ schoolidk
)

math_missing_se <- vcovCL(
  math_missing_model,
  cluster = ~ schoolidk
)

# Count schools in each model
reading_schools <- length(unique(
  model.frame(reading_missing_model)$schoolidk
))

math_schools <- length(unique(
  model.frame(math_missing_model)$schoolidk
))

# Show class-type differences in missingness
reading_missing_results <- coeftest(
  reading_missing_model,
  vcov. = reading_missing_se,
  df = reading_schools - 1
)

math_missing_results <- coeftest(
  math_missing_model,
  vcov. = math_missing_se,
  df = math_schools - 1
)

reading_missing_results[1:3, ]
math_missing_results[1:3, ]

# Check sample sizes
nobs(reading_missing_model)
nobs(math_missing_model)

# Save missing-score comparisons
write.csv(
  reading_missing_results[1:3, ],
  "outputs/reading_missing_results.csv"
)

write.csv(
  math_missing_results[1:3, ],
  "outputs/math_missing_results.csv"
)