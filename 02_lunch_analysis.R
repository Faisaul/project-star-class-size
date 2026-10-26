library(lmtest)
library(sandwich)

# Load the data saved by script 01
star_k <- readRDS("outputs/kindergarten_data.rds")

# Check free-lunch eligibility
table(star_k$lunchk, useNA = "ifany")
table(star_k$stark, star_k$lunchk, useNA = "ifany")

# Use non-free lunch as the comparison group
star_k$lunchk <- relevel(star_k$lunchk, ref = "non-free")

# See whether class differences vary by lunch eligibility
reading_lunch <- lm(
  readk ~ stark * lunchk + schoolidk,
  data = star_k
)

math_lunch <- lm(
  mathk ~ stark * lunchk + schoolidk,
  data = star_k
)

# Cluster standard errors by school
reading_se <- vcovCL(reading_lunch, cluster = ~ schoolidk)
math_se <- vcovCL(math_lunch, cluster = ~ schoolidk)

# Count the schools used in each model
reading_schools <- length(unique(
  model.frame(reading_lunch)$schoolidk
))

math_schools <- length(unique(
  model.frame(math_lunch)$schoolidk
))

# Get the results
reading_results <- coeftest(
  reading_lunch,
  vcov. = reading_se,
  df = reading_schools - 1
)

math_results <- coeftest(
  math_lunch,
  vcov. = math_se,
  df = math_schools - 1
)

# Show class-type and interaction coefficients
reading_results[grepl("stark", rownames(reading_results)), ]
math_results[grepl("stark", rownames(math_results)), ]

# Check sample sizes
nobs(reading_lunch)
nobs(math_lunch)

# Save the interaction results
write.csv(
  reading_results,
  "outputs/reading_lunch_results.csv"
)

write.csv(
  math_results,
  "outputs/math_lunch_results.csv"
)
# Save only the class-type and interaction results
reading_table <- reading_results[
  grepl("stark", rownames(reading_results)), ]

math_table <- math_results[
  grepl("stark", rownames(math_results)), ]

write.csv(reading_table, "outputs/reading_lunch_results.csv")
write.csv(math_table, "outputs/math_lunch_results.csv")

# Small vs regular: free-lunch group

# Reading estimate
reading_free <- coef(reading_lunch)["starksmall"] +
  coef(reading_lunch)["starksmall:lunchkfree"]

# Reading standard error
reading_free_se <- sqrt(
  reading_se["starksmall", "starksmall"] +
    reading_se["starksmall:lunchkfree", "starksmall:lunchkfree"] +
    2 * reading_se["starksmall", "starksmall:lunchkfree"]
)

# Reading 95% confidence interval
reading_critical <- qt(0.975, df = reading_schools - 1)

reading_free
reading_free_se

reading_free + c(-1, 1) * reading_critical * reading_free_se


# Math estimate
math_free <- coef(math_lunch)["starksmall"] +
  coef(math_lunch)["starksmall:lunchkfree"]

# Math standard error
math_free_se <- sqrt(
  math_se["starksmall", "starksmall"] +
    math_se["starksmall:lunchkfree", "starksmall:lunchkfree"] +
    2 * math_se["starksmall", "starksmall:lunchkfree"]
)

# Math 95% confidence interval
math_critical <- qt(0.975, df = math_schools - 1)

math_free
math_free_se

math_free + c(-1, 1) * math_critical * math_free_se

# Save small-class estimates for the free-lunch group
free_lunch_results <- data.frame(
  outcome = c("Reading", "Math"),
  estimate = c(reading_free, math_free),
  standard_error = c(reading_free_se, math_free_se),
  lower_95 = c(
    reading_free - reading_critical * reading_free_se,
    math_free - math_critical * math_free_se
  ),
  upper_95 = c(
    reading_free + reading_critical * reading_free_se,
    math_free + math_critical * math_free_se
  )
)

write.csv(
  free_lunch_results,
  "outputs/free_lunch_results.csv",
  row.names = FALSE
)