test_that("Griffit model creation works", {
  skip_on_cran()
  
  data <- data.frame(
    y = rnorm(50),
    x1 = rnorm(50),
    x2 = rnorm(50)
  )
  
  model <- griffit_model(y ~ x1 + x2, data = data)
  
  expect_s4_class(model, "GriffitModel")
  expect_true(is.numeric(coef(model)))
  expect_true(is.numeric(residuals(model)))
  expect_true(is.numeric(fitted(model)))
  expect_true(is.numeric(logLik(model)))
  expect_true(is.numeric(AIC(model)))
  expect_true(is.numeric(BIC(model)))
})

test_that("Griffit model summary works", {
  skip_on_cran()
  
  data <- data.frame(
    y = rnorm(30),
    x1 = rnorm(30),
    x2 = rnorm(30)
  )
  
  model <- griffit_model(y ~ x1 + x2, data = data)
  summ <- summary(model)
  
  expect_s3_class(summ, "summary.GriffitModel")
  expect_true("coefficients" %in% names(summ))
  expect_true("loglik" %in% names(summ))
})

test_that("Griffit diagnostic works", {
  skip_on_cran()
  
  data <- data.frame(
    y = rnorm(40),
    x1 = rnorm(40)
  )
  
  model <- griffit_model(y ~ x1, data = data)
  diag <- griffit_diagnostic(model, test = "residuals")
  
  expect_s3_class(diag, "GriffitDiagnostic")
  expect_true("test" %in% names(diag))
  expect_true("p.value" %in% names(diag))
})

test_that("Griffit prediction works", {
  skip_on_cran()
  
  data <- data.frame(
    y = rnorm(20),
    x1 = rnorm(20),
    x2 = rnorm(20)
  )
  
  model <- griffit_model(y ~ x1 + x2, data = data)
  pred <- predict(model)
  
  expect_s3_class(pred, "GriffitPredict")
  expect_true("fit" %in% names(pred))
  expect_equal(length(pred$fit), 20)
})

test_that("Griffit simulation works", {
  skip_on_cran()
  
  simulated_data <- griffit_simulate(n = 50, p = 2, seed = 123)
  
  expect_s3_class(simulated_data, "data.frame")
  expect_equal(nrow(simulated_data), 50)
  expect_equal(ncol(simulated_data), 3) # y + x1 + x2
  expect_true("y" %in% names(simulated_data))
})

test_that("Griffit cross-validation works", {
  skip_on_cran()
  
  data <- data.frame(
    y = rnorm(60),
    x1 = rnorm(60),
    x2 = rnorm(60)
  )
  
  cv_result <- griffit_cv(y ~ x1 + x2, data = data, folds = 3)
  
  expect_s3_class(cv_result, "GriffitCV")
  expect_true("cv_errors" %in% names(cv_result))
  expect_true("mean_cv_error" %in% names(cv_result))
  expect_equal(length(cv_result$cv_errors), 3)
})