#' Modèle Griffith pour l'Analyse Spatiale
#'
#' Ce package implémente le modèle Griffith pour l'analyse de données spatiales
#' et temporelles avec diverses méthodes d'estimation et de validation.
#'
#' @docType package
#' @name griffit
#' @keywords internal
"_PACKAGE"

# ============================================================================
# CLASSES DE BASE
# ============================================================================

#' Classe pour les résultats du modèle Griffith
#'
#' @slot coefficients Coefficients estimés
#' @slot residuals Résidus du modèle
#' @slot fitted.values Valeurs ajustées
#' @slot variance Matrice de variance-covariance
#' @slot loglikelihood Log-vraisemblance
#' @slot aic Critère AIC
#' @slot bic Critère BIC
#' @slot convergence État de convergence
#' @slot iterations Nombre d'itérations
#' @slot call Appel de la fonction
#' @export
setClass("GriffitModel",
         slots = list(
           coefficients = "numeric",
           residuals = "numeric",
           fitted.values = "numeric",
           variance = "matrix",
           loglikelihood = "numeric",
           aic = "numeric",
           bic = "numeric",
           convergence = "logical",
           iterations = "numeric",
           call = "call"
         ),
         prototype = list(
           coefficients = numeric(),
           residuals = numeric(),
           fitted.values = numeric(),
           variance = matrix(),
           loglikelihood = numeric(),
           aic = numeric(),
           bic = numeric(),
           convergence = logical(),
           iterations = numeric(),
           call = call("griffit_model")
         ))

#' Crée un objet GriffithModel
#'
#' @param coefficients Coefficients estimés
#' @param residuals Résidus
#' @param fitted.values Valeurs ajustées
#' @param variance Matrice de variance-covariance
#' @param loglikelihood Log-vraisemblance
#' @param convergence État de convergence
#' @param iterations Nombre d'itérations
#' @param call Appel de la fonction
#' @return Un objet GriffithModel
#' @keywords internal
create_griffit_model <- function(coefficients, residuals, fitted.values, 
                                 variance, loglikelihood, convergence, 
                                 iterations, call) {
  aic <- -2 * loglikelihood + 2 * length(coefficients)
  bic <- -2 * loglikelihood + length(coefficients) * log(length(residuals))
  
  new("GriffitModel",
      coefficients = coefficients,
      residuals = residuals,
      fitted.values = fitted.values,
      variance = variance,
      loglikelihood = loglikelihood,
      aic = aic,
      bic = bic,
      convergence = convergence,
      iterations = iterations,
      call = call)
}

# ============================================================================
# FONCTIONS PRINCIPALES
# ============================================================================

#' Estimation du Modèle Griffith
#'
#' Estime les paramètres du modèle Griffith pour des données spatiales.
#'
#' @param formula Une formule spécifiant le modèle
#' @param data Un data.frame contenant les données
#' @param weights Poids optionnels pour les observations
#' @param method Méthode d'estimation ("ml" pour maximum de vraisemblance,
#'   "gls" pour moindres carrés généralisés)
#' @param control Liste de paramètres de contrôle
#' @param ... Arguments supplémentaires
#'
#' @return Un objet de classe GriffithModel
#' @export
#'
#' @examples
#' \dontrun{
#' data <- data.frame(
#'   y = rnorm(100),
#'   x1 = rnorm(100),
#'   x2 = rnorm(100),
#'   spatial_lag = rnorm(100)
#' )
#' model <- griffit_model(y ~ x1 + x2 + spatial_lag, data = data)
#' summary(model)
#' }
griffit_model <- function(formula, data, weights = NULL, 
                          method = c("ml", "gls"), 
                          control = list(), ...) {
  
  method <- match.arg(method)
  call <- match.call()
  
  if (!inherits(formula, "formula")) {
    stop("L'argument 'formula' doit être une formule")
  }
  
  if (!is.data.frame(data)) {
    stop("L'argument 'data' doit être un data.frame")
  }
  
  mf <- model.frame(formula, data)
  y <- model.response(mf, "numeric")
  X <- model.matrix(formula, mf)
  
  if (is.null(weights)) {
    weights <- rep(1, length(y))
  }
  
  control_defaults <- list(
    maxit = 100,
    tol = 1e-8,
    trace = FALSE,
    optim_method = "BFGS"
  )
  
  control <- modifyList(control_defaults, control)
  
  result <- switch(method,
    ml = estimate_ml(y, X, weights, control),
    gls = estimate_gls(y, X, weights, control)
  )
  
  fitted_values <- X %*% result$coefficients
  residuals_val <- y - fitted_values
  
  model <- create_griffit_model(
    coefficients = result$coefficients,
    residuals = as.numeric(residuals_val),
    fitted.values = as.numeric(fitted_values),
    variance = result$variance,
    loglikelihood = result$loglikelihood,
    convergence = result$convergence,
    iterations = result$iterations,
    call = call
  )
  
  return(model)
}

#' Estimation par Maximum de Vraisemblance
#'
#' @param y Variable réponse
#' @param X Matrice de design
#' @param weights Poids
#' @param control Paramètres de contrôle
#' @return Liste avec résultats
#' @keywords internal
estimate_ml <- function(y, X, weights, control) {
  n <- length(y)
  p <- ncol(X)
  
  initial_params <- rep(0.1, p)
  
  loglik_function <- function(params) {
    beta <- params
    mu <- X %*% beta
    sigma2 <- mean((y - mu)^2)
    
    ll <- -0.5 * n * log(2 * pi * sigma2) - 
           0.5 * sum((y - mu)^2) / sigma2
    
    return(-ll)
  }
  
  gradient_function <- function(params) {
    beta <- params
    mu <- X %*% beta
    sigma2 <- mean((y - mu)^2)
    
    grad_beta <- t(X) %*% (y - mu) / sigma2
    
    return(-grad_beta)
  }
  
  tryCatch({
    optim_result <- stats::optim(
      par = initial_params,
      fn = loglik_function,
      gr = gradient_function,
      method = control$optim_method,
      control = list(
        maxit = control$maxit,
        reltol = control$tol,
        trace = control$trace
      )
    )
    
    coefficients <- optim_result$par
    convergence <- optim_result$convergence == 0
    iterations <- NA_real_
    
    mu <- X %*% coefficients
    sigma2 <- mean((y - mu)^2)
    
    variance <- solve(t(X) %*% X) * sigma2
    
    list(
      coefficients = coefficients,
      variance = variance,
      loglikelihood = -optim_result$value,
      convergence = convergence,
      iterations = iterations
    )
  }, error = function(e) {
    stop("Erreur dans l'estimation ML: ", e$message)
  })
}

#' Estimation par Moindres Carrés Généralisés
#'
#' @param y Variable réponse
#' @param X Matrice de design
#' @param weights Poids
#' @param control Paramètres de contrôle
#' @return Liste avec résultats
#' @keywords internal
estimate_gls <- function(y, X, weights, control) {
  W <- diag(weights)
  
  coefficients <- solve(t(X) %*% W %*% X) %*% t(X) %*% W %*% y
  residuals <- y - X %*% coefficients
  
  sigma2 <- sum(weights * residuals^2) / (length(y) - ncol(X))
  variance <- sigma2 * solve(t(X) %*% W %*% X)
  
  loglikelihood <- -0.5 * length(y) * log(2 * pi * sigma2) - 
                    0.5 * sum(weights * residuals^2) / sigma2
  
  list(
    coefficients = as.numeric(coefficients),
    variance = variance,
    loglikelihood = loglikelihood,
    convergence = TRUE,
    iterations = 1
  )
}

#' Test de Diagnostic Griffith
#'
#' Effectue des tests de diagnostic sur un modèle Griffith.
#'
#' @param object Un objet GriffithModel
#' @param test Type de test ("residuals", "autocorrelation", "heteroscedasticity")
#' @param lag Ordre du test pour l'autocorrélation
#' @return Un objet avec les résultats du test
#' @export
#'
#' @examples
#' \dontrun{
#' model <- griffit_model(y ~ x1 + x2, data = mydata)
#' diagnostic <- griffit_diagnostic(model, test = "residuals")
#' print(diagnostic)
#' }
griffit_diagnostic <- function(object, 
                               test = c("residuals", "autocorrelation", 
                                       "heteroscedasticity"),
                               lag = 1) {
  
  if (!inherits(object, "GriffitModel")) {
    stop("L'objet doit être de classe GriffithModel")
  }
  
  test <- match.arg(test)
  residuals <- object@residuals
  n <- length(residuals)
  
  result <- switch(test,
    residuals = {
      list(
        test = "Residual Normality Test",
        statistic = shapiro_test(residuals),
        p.value = stats::shapiro.test(residuals)$p.value,
        conclusion = ifelse(stats::shapiro.test(residuals)$p.value > 0.05,
                           "Residuals appear normal",
                           "Residuals not normal")
      )
    },
    
    autocorrelation = {
      if (lag < 1 || lag >= n) {
        stop("Lag must be between 1 and n-1")
      }
      
      acf_val <- stats::acf(residuals, lag.max = lag, plot = FALSE)$acf[lag + 1]
      test_stat <- n * acf_val^2
      p_value <- 1 - stats::pchisq(test_stat, df = 1)
      
      list(
        test = paste("Autocorrelation Test (lag =", lag, ")"),
        statistic = test_stat,
        p.value = p_value,
        autocorrelation = acf_val,
        conclusion = ifelse(p_value > 0.05,
                           "No significant autocorrelation",
                           "Significant autocorrelation present")
      )
    },
    
    heteroscedasticity = {
      fitted <- object@fitted.values
      squared_residuals <- residuals^2
      
      test_lm <- stats::lm(squared_residuals ~ fitted)
      test_stat <- n * summary(test_lm)$r.squared
      p_value <- 1 - stats::pchisq(test_stat, df = 1)
      
      list(
        test = "Heteroscedasticity Test",
        statistic = test_stat,
        p.value = p_value,
        conclusion = ifelse(p_value > 0.05,
                           "No significant heteroscedasticity",
                           "Heteroscedasticity detected")
      )
    }
  )
  
  class(result) <- "GriffitDiagnostic"
  return(result)
}

#' Test de Shapiro simplifié
#'
#' @param x Vecteur numérique
#' @return Statistique W
#' @keywords internal
shapiro_test <- function(x) {
  n <- length(x)
  x <- sort(x)
  
  if (n < 3) {
    return(NA)
  }
  
  m <- stats::qnorm((seq_len(n) - 0.375) / (n + 0.25))
  a <- coefficients_shapiro(n)
  
  w <- sum(a * x)^2 / sum((x - mean(x))^2)
  return(w)
}

#' Coefficients pour le test de Shapiro
#'
#' @param n Taille de l'échantillon
#' @return Coefficients
#' @keywords internal
coefficients_shapiro <- function(n) {
  m <- stats::qnorm((seq_len(n) - 0.375) / (n + 0.25))
  u <- 1 / sqrt(n)
  
  coefficients <- numeric(n)
  
  for (i in seq_len(n)) {
    if (i == 1 || i == n) {
      coefficients[i] <- -2.706056 * u^5 + 4.434685 * u^4 - 
                         2.071190 * u^3 - 0.147981 * u^2 + 
                         0.221157 * u + m[i]
    } else {
      coefficients[i] <- -3.582633 * u^5 + 5.682633 * u^4 - 
                         1.752461 * u^3 - 0.293762 * u^2 + 
                         0.042981 * u + m[i]
    }
  }
  
  return(coefficients)
}

#' Prédictions avec le Modèle Griffith
#'
#' Calcule des prédictions à partir d'un modèle Griffith estimé.
#'
#' @param object Un objet GriffithModel
#' @param newdata Nouvelles données pour la prédiction
#' @param interval Type d'intervalle ("none", "confidence", "prediction")
#' @param level Niveau de confiance (par défaut 0.95)
#' @param ... Arguments supplémentaires
#'
#' @return Un objet avec les prédictions
#' @export
#'
#' @examples
#' \dontrun{
#' model <- griffit_model(y ~ x1 + x2, data = train_data)
#' predictions <- predict(model, newdata = test_data)
#' }
predict.GriffitModel <- function(object, newdata = NULL, 
                                 interval = c("none", "confidence", "prediction"),
                                 level = 0.95, ...) {
  
  interval <- match.arg(interval)
  
  if (is.null(newdata)) {
    fitted_values <- object@fitted.values
    X <- model.matrix(object@call$formula, 
                      model.frame(object@call$formula, 
                                 object@call$data))
  } else {
    if (!is.data.frame(newdata)) {
      stop("newdata doit être un data.frame")
    }
    
    formula <- object@call$formula
    mf <- model.frame(formula, newdata)
    X <- model.matrix(formula, mf)
    fitted_values <- as.numeric(X %*% object@coefficients)
  }
  
  result <- list(
    fit = fitted_values,
    se.fit = NULL,
    df = length(object@residuals) - length(object@coefficients),
    residual.scale = sqrt(mean(object@residuals^2)),
    level = level
  )
  
  if (interval != "none") {
    sigma <- sqrt(diag(object@variance))
    se <- sqrt(diag(X %*% object@variance %*% t(X)))
    
    if (interval == "prediction") {
      sigma_total <- sqrt(result$residual.scale^2 + se^2)
      se <- sigma_total
    }
    
    t_val <- stats::qt(1 - (1 - level)/2, result$df)
    margin_error <- t_val * se
    
    result$se.fit <- se
    result$lower <- fitted_values - margin_error
    result$upper <- fitted_values + margin_error
  }
  
  class(result) <- "GriffitPredict"
  return(result)
}

#' Validation Croisée pour Modèle Griffith
#'
#' Effectue une validation croisée sur un modèle Griffith.
#'
#' @param formula Une formule spécifiant le modèle
#' @param data Un data.frame contenant les données
#' @param folds Nombre de folds (par défaut 5)
#' @param method Méthode d'estimation
#' @param ... Arguments supplémentaires pour griffit_model
#'
#' @return Un objet avec les résultats de la validation croisée
#' @export
#'
#' @examples
#' \dontrun{
#' cv_result <- griffit_cv(y ~ x1 + x2, data = mydata, folds = 10)
#' summary(cv_result)
#' }
griffit_cv <- function(formula, data, folds = 5, method = "ml", ...) {
  
  if (!inherits(formula, "formula")) {
    stop("L'argument 'formula' doit être une formule")
  }
  
  if (!is.data.frame(data)) {
    stop("L'argument 'data' doit être un data.frame")
  }
  
  n <- nrow(data)
  indices <- sample(rep(1:folds, length.out = n))
  
  cv_errors <- numeric(folds)
  coefficients_list <- list()
  
  for (k in 1:folds) {
    train_data <- data[indices != k, ]
    test_data <- data[indices == k, ]
    
    tryCatch({
      model <- griffit_model(formula, data = train_data, 
                            method = method, ...)
      
      predictions <- predict(model, newdata = test_data)
      y_test <- model.response(model.frame(formula, test_data), "numeric")
      
      cv_errors[k] <- mean((y_test - predictions$fit)^2, na.rm = TRUE)
      coefficients_list[[k]] <- model@coefficients
      
    }, error = function(e) {
      cv_errors[k] <- NA
      coefficients_list[[k]] <- rep(NA, length(model@coefficients))
    })
  }
  
  coefficients_matrix <- do.call(rbind, coefficients_list)
  colnames(coefficients_matrix) <- names(model@coefficients)
  
  result <- list(
    cv_errors = cv_errors,
    mean_cv_error = mean(cv_errors, na.rm = TRUE),
    sd_cv_error = sd(cv_errors, na.rm = TRUE),
    coefficients = coefficients_matrix,
    folds = folds,
    method = method,
    call = match.call()
  )
  
  class(result) <- "GriffitCV"
  return(result)
}

#' Simulation de Données selon le Modèle Griffith
#'
#' Génère des données simulées selon le modèle Griffith.
#'
#' @param n Nombre d'observations
#' @param p Nombre de variables explicatives
#' @param beta Coefficients réels (si NULL, générés aléatoirement)
#' @param sigma Écart-type des erreurs
#' @param spatial_corr Corrélation spatiale (entre 0 et 1)
#' @param seed Graine pour la reproductibilité
#'
#' @return Un data.frame avec les données simulées
#' @export
#'
#' @examples
#' \dontrun{
#' simulated_data <- griffit_simulate(n = 100, p = 3)
#' model <- griffit_model(y ~ ., data = simulated_data)
#' }
griffit_simulate <- function(n = 100, p = 3, beta = NULL, sigma = 1, 
                            spatial_corr = 0.5, seed = NULL) {
  
  if (!is.null(seed)) {
    set.seed(seed)
  }
  
  if (is.null(beta)) {
    beta <- stats::rnorm(p, mean = 0, sd = 1)
  }
  
  X <- matrix(stats::rnorm(n * p), nrow = n, ncol = p)
  colnames(X) <- paste0("x", 1:p)
  
  if (spatial_corr > 0) {
    W <- matrix(0, n, n)
    for (i in 1:n) {
      for (j in 1:n) {
        if (i != j) {
          W[i, j] <- exp(-abs(i - j) / (n * spatial_corr))
        }
      }
    }
    
    epsilon <- MASS::mvrnorm(1, mu = rep(0, n), 
                            Sigma = sigma^2 * solve(diag(n) - spatial_corr * W))
  } else {
    epsilon <- stats::rnorm(n, mean = 0, sd = sigma)
  }
  
  y <- X %*% beta + epsilon
  
  data <- data.frame(y = as.numeric(y), X)
  return(data)
}

#' Sélection de Variables pour Modèle Griffith
#'
#' Effectue une sélection de variables pour le modèle Griffith.
#'
#' @param formula Une formule complète avec toutes les variables potentielles
#' @param data Un data.frame contenant les données
#' @param criterion Critère de sélection ("aic", "bic", "cv")
#' @param direction Direction de la recherche ("both", "forward", "backward")
#' @param ... Arguments supplémentaires
#'
#' @return Un objet avec les résultats de la sélection
#' @export
#'
#' @examples
#' \dontrun{
#' full_formula <- y ~ x1 + x2 + x3 + x4
#' selection <- griffit_select(full_formula, data = mydata, criterion = "aic")
#' }
griffit_select <- function(formula, data, 
                          criterion = c("aic", "bic", "cv"),
                          direction = c("both", "forward", "backward"),
                          ...) {
  
  criterion <- match.arg(criterion)
  direction <- match.arg(direction)
  
  mf <- model.frame(formula, data)
  X <- model.matrix(formula, mf)
  y <- model.response(mf, "numeric")
  
  variable_names <- colnames(X)
  p <- length(variable_names)
  
  if (direction == "backward") {
    current_model <- griffit_model(formula, data = data, ...)
    current_criterion <- get_criterion(current_model, criterion)
    
    results <- data.frame(
      variables = paste(variable_names, collapse = "+"),
      criterion = current_criterion,
      stringsAsFactors = FALSE
    )
    
    for (k in (p-1):1) {
      best_criterion <- Inf
      best_combination <- NULL
      
      combinations <- combn(p, k)
      
      for (i in 1:ncol(combinations)) {
        vars <- variable_names[combinations[, i]]
        current_formula <- reformulate(vars, response = formula[[2]])
        
        tryCatch({
          model <- griffit_model(current_formula, data = data, ...)
          current_crit <- get_criterion(model, criterion)
          
          if (current_crit < best_criterion) {
            best_criterion <- current_crit
            best_combination <- vars
          }
        }, error = function(e) {
          # Ignorer les modèles qui échouent
        })
      }
      
      results <- rbind(results, data.frame(
        variables = paste(best_combination, collapse = "+"),
        criterion = best_criterion,
        stringsAsFactors = FALSE
      ))
    }
  } else {
    stop("Forward et both directions pas encore implémentées")
  }
  
  result <- list(
    selection_results = results,
    best_model = which.min(results$criterion),
    best_criterion = min(results$criterion),
    criterion = criterion,
    direction = direction,
    call = match.call()
  )
  
  class(result) <- "GriffitSelect"
  return(result)
}

#' Obtient le critère de sélection
#'
#' @param model Modèle Griffith
#' @param criterion Critère
#' @return Valeur du critère
#' @keywords internal
get_criterion <- function(model, criterion) {
  switch(criterion,
         aic = model@aic,
         bic = model@bic,
         cv = {
           cv_result <- griffit_cv(model@call$formula, 
                                  data = eval(model@call$data))
           cv_result$mean_cv_error
         })
}

# ============================================================================
# MÉTHODES GÉNÉRIQUES
# ============================================================================

#' Affiche un résumé du Modèle Griffith
#'
#' @param object Un objet GriffithModel
#' @param ... Arguments supplémentaires
#'
#' @return Un objet summary.GriffitModel (invisible)
#' @export
#'
#' @examples
#' \dontrun{
#' model <- griffit_model(y ~ x1 + x2, data = mydata)
#' summary(model)
#' }
summary.GriffitModel <- function(object, ...) {
  
  coefficients <- object@coefficients
  se <- sqrt(diag(object@variance))
  t_values <- coefficients / se
  p_values <- 2 * stats::pt(abs(t_values), 
                           df = length(object@residuals) - length(coefficients), 
                           lower.tail = FALSE)
  
  coef_matrix <- cbind(
    Estimate = coefficients,
    Std.Error = se,
    t.value = t_values,
    p.value = p_values
  )
  
  rownames(coef_matrix) <- names(coefficients)
  
  result <- list(
    call = object@call,
    coefficients = coef_matrix,
    residuals = object@residuals,
    sigma = sqrt(mean(object@residuals^2)),
    df = c(length(coefficients), 
           length(object@residuals) - length(coefficients),
           length(coefficients)),
    loglik = object@loglikelihood,
    aic = object@aic,
    bic = object@bic,
    convergence = object@convergence,
    iterations = object@iterations
  )
  
  class(result) <- "summary.GriffitModel"
  return(result)
}

#' Affiche le résumé formaté
#'
#' @param x Un objet summary.GriffitModel
#' @param digits Nombre de décimales
#' @param ... Arguments supplémentaires
#' @export
print.summary.GriffitModel <- function(x, digits = 3, ...) {
  
  cat("Call:\n")
  print(x$call)
  cat("\n")
  
  cat("Coefficients:\n")
  printCoefmat(x$coefficients, digits = digits, 
               signif.stars = TRUE, 
               na.print = "NA", 
               has.Pvalue = TRUE)
  cat("\n")
  
  cat("Residual standard error:", 
      format(x$sigma, digits = digits), 
      "on", x$df[2], "degrees of freedom\n")
  
  cat("Log-likelihood:", format(x$loglik, digits = digits), "\n")
  cat("AIC:", format(x$aic, digits = digits), "\n")
  cat("BIC:", format(x$bic, digits = digits), "\n")
  cat("Convergence:", ifelse(x$convergence, "Achieved", "Failed"), "\n")
  
  if (!is.na(x$iterations)) {
    cat("Iterations:", x$iterations, "\n")
  }
  
  invisible(x)
}

#' Affiche un Modèle Griffith
#'
#' @param x Un objet GriffithModel
#' @param ... Arguments supplémentaires
#' @export
print.GriffitModel <- function(x, ...) {
  cat("Griffit Model\n")
  cat("Call: ")
  print(x@call)
  cat("\n")
  
  cat("Coefficients:\n")
  print(x@coefficients)
  cat("\n")
  
  cat("Log-likelihood:", x@loglikelihood, "\n")
  cat("AIC:", x@aic, "\n")
  cat("BIC:", x@bic, "\n")
  cat("Convergence:", ifelse(x@convergence, "Yes", "No"), "\n")
  
  invisible(x)
}

#' Affiche les Prédictions Griffith
#'
#' @param x Un objet GriffitPredict
#' @param ... Arguments supplémentaires
#' @export
print.GriffitPredict <- function(x, ...) {
  cat("Griffit Model Predictions\n\n")
  
  if (is.null(x$se.fit)) {
    result <- data.frame(Fit = x$fit)
  } else {
    result <- data.frame(
      Fit = x$fit,
      SE = x$se.fit,
      Lower = x$lower,
      Upper = x$upper
    )
  }
  
  print(head(result, 10))
  
  if (nrow(result) > 10) {
    cat("... [", nrow(result) - 10, "more predictions]\n")
  }
  
  invisible(x)
}

#' Affiche les Résultats de Validation Croisée
#'
#' @param x Un objet GriffitCV
#' @param ... Arguments supplémentaires
#' @export
print.GriffitCV <- function(x, ...) {
  cat("Griffit Model Cross-Validation\n")
  cat("Folds:", x$folds, "\n")
  cat("Method:", x$method, "\n")
  cat("\n")
  
  cat("Cross-Validation Errors per fold:\n")
  print(x$cv_errors)
  cat("\n")
  
  cat("Mean CV Error:", format(x$mean_cv_error, digits = 4), "\n")
  cat("SD CV Error:", format(x$sd_cv_error, digits = 4), "\n")
  
  invisible(x)
}

#' Affiche les Résultats de Diagnostic
#'
#' @param x Un objet GriffitDiagnostic
#' @param ... Arguments supplémentaires
#' @export
print.GriffitDiagnostic <- function(x, ...) {
  cat("Griffit Model Diagnostic Test\n")
  cat("Test:", x$test, "\n")
  cat("Statistic:", format(x$statistic, digits = 4), "\n")
  cat("p-value:", format(x$p.value, digits = 4), "\n")
  cat("Conclusion:", x$conclusion, "\n")
  
  invisible(x)
}

#' Affiche les Résultats de Sélection
#'
#' @param x Un objet GriffitSelect
#' @param ... Arguments supplémentaires
#' @export
print.GriffitSelect <- function(x, ...) {
  cat("Griffit Model Variable Selection\n")
  cat("Criterion:", x$criterion, "\n")
  cat("Direction:", x$direction, "\n")
  cat("\n")
  
  cat("Selection results:\n")
  print(x$selection_results)
  cat("\n")
  
  cat("Best model (row", x$best_model, "):\n")
  cat("Variables:", x$selection_results$variables[x$best_model], "\n")
  cat("Criterion value:", x$best_criterion, "\n")
  
  invisible(x)
}

#' Graphique des Résidus du Modèle Griffith
#'
#' @param x Un objet GriffithModel
#' @param type Type de graphique ("residuals", "qq", "fitted")
#' @param ... Arguments supplémentaires
#' @export
#'
#' @examples
#' \dontrun{
#' model <- griffit_model(y ~ x1 + x2, data = mydata)
#' plot(model, type = "residuals")
#' }
plot.GriffitModel <- function(x, type = c("residuals", "qq", "fitted"), ...) {
  
  type <- match.arg(type)
  residuals <- x@residuals
  fitted <- x@fitted.values
  
  oldpar <- par(no.readonly = TRUE)
  on.exit(par(oldpar))
  
  par(mfrow = c(1, 1))
  
  switch(type,
    residuals = {
      plot(residuals, type = "h", main = "Residuals Plot",
           xlab = "Observation", ylab = "Residuals", 
           col = "steelblue", lwd = 2, ...)
      abline(h = 0, col = "red", lty = 2)
      lines(lowess(seq_along(residuals), residuals), 
            col = "darkgreen", lwd = 2)
    },
    
    qq = {
      stats::qqnorm(residuals, main = "Normal Q-Q Plot",
                    xlab = "Theoretical Quantiles", 
                    ylab = "Sample Quantiles", ...)
      stats::qqline(residuals, col = "red", lwd = 2)
    },
    
    fitted = {
      plot(fitted, residuals, main = "Residuals vs Fitted",
           xlab = "Fitted Values", ylab = "Residuals",
           pch = 19, col = "steelblue", ...)
      abline(h = 0, col = "red", lty = 2)
      lines(lowess(fitted, residuals), col = "darkgreen", lwd = 2)
    }
  )
}

#' Coefficients du Modèle Griffith
#'
#' @param object Un objet GriffithModel
#' @param ... Arguments supplémentaires
#' @return Les coefficients du modèle
#' @export
coef.GriffitModel <- function(object, ...) {
  return(object@coefficients)
}

#' Résidus du Modèle Griffith
#'
#' @param object Un objet GriffithModel
#' @param ... Arguments supplémentaires
#' @return Les résidus du modèle
#' @export
residuals.GriffitModel <- function(object, ...) {
  return(object@residuals)
}

#' Valeurs Ajustées du Modèle Griffith
#'
#' @param object Un objet GriffithModel
#' @param ... Arguments supplémentaires
#' @return Les valeurs ajustées
#' @export
fitted.GriffitModel <- function(object, ...) {
  return(object@fitted.values)
}

#' Log-Vraisemblance du Modèle Griffith
#'
#' @param object Un objet GriffithModel
#' @param ... Arguments supplémentaires
#' @return La log-vraisemblance
#' @export
logLik.GriffitModel <- function(object, ...) {
  return(object@loglikelihood)
}

#' AIC du Modèle Griffith
#'
#' @param object Un objet GriffithModel
#' @param ... Arguments supplémentaires
#' @return L'AIC
#' @export
AIC.GriffitModel <- function(object, ...) {
  return(object@aic)
}

#' BIC du Modèle Griffith
#'
#' @param object Un objet GriffithModel
#' @param ... Arguments supplémentaires
#' @return Le BIC
#' @export
BIC.GriffitModel <- function(object, ...) {
  return(object@bic)
}