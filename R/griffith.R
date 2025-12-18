#' Calcul de la contrainte critique selon Griffith
#'
#' @param E Module d'Young du matériau (en Pa ou MPa)
#' @param gamma Densité d'énergie de surface (en J/m²)
#' @param a Demi-longueur de la fissure (en m)
#' @param type Type de fissure: "internal" (interne) ou "edge" (bordante)
#' @param nu Coefficient de Poisson (optionnel, pour déformation plane)
#' @return La contrainte critique σ_c (mêmes unités que E)
#' @examples
#' # Verre: E=70 GPa, gamma=1 J/m², fissure de 1 mm
#' sigma_critique(E = 70e9, gamma = 1, a = 0.001)
#' @export
sigma_critique <- function(E, gamma, a, type = "internal", nu = NULL) {
  if (any(c(E, gamma, a) <= 0)) {
    stop("Tous les paramètres (E, gamma, a) doivent être positifs")
  }
  
  if (type == "internal") {
    Y <- sqrt(pi)
  } else if (type == "edge") {
    Y <- 1.12 * sqrt(pi)
  } else {
    stop("Type doit être 'internal' ou 'edge'")
  }
  
  if (!is.null(nu)) {
    E_prime <- E / (1 - nu^2)
  } else {
    E_prime <- E
  }
  
  sigma_c <- sqrt(2 * E_prime * gamma / (pi * a)) * (1 / Y)
  return(sigma_c)
}

#' Calcul du facteur d'intensité de contrainte
#'
#' @param sigma Contrainte appliquée (en Pa ou MPa)
#' @param a Longueur de la fissure (en m)
#' @param type Type de fissure: "internal" ou "edge"
#' @return Facteur d'intensité de contrainte K (en Pa√m ou MPa√m)
#' @examples
#' stress_intensity(sigma = 100e6, a = 0.001, type = "edge")
#' @export
stress_intensity <- function(sigma, a, type = "internal") {
  if (type == "internal") {
    Y <- sqrt(pi)
  } else {
    Y <- 1.12 * sqrt(pi)
  }
  
  K <- sigma * sqrt(pi * a) * Y
  return(K)
}

#' Vérification du critère de rupture
#'
#' @param K_applied Facteur d'intensité de contrainte appliqué
#' @param K_c Ténacité du matériau (K_IC)
#' @return Liste avec verdict et marge de sécurité
#' @examples
#' check_rupture(K_applied = 40, K_c = 50)
#' @export
check_rupture <- function(K_applied, K_c) {
  safety_margin <- K_c / K_applied
  
  if (K_applied >= K_c) {
    verdict <- "RUPTURE"
  } else if (safety_margin < 1.5) {
    verdict <- "ATTENTION"
  } else {
    verdict <- "STABLE"
  }
  
  list(
    verdict = verdict,
    safety_margin = safety_margin,
    K_applied = K_applied,
    K_critical = K_c
  )
}

#' Ajustement de la loi de Paris pour la propagation de fissure
#'
#' @param deltaK Vecteur des valeurs ΔK
#' @param dadN Vecteur des vitesses de propagation (da/dN)
#' @return Liste avec paramètres C, m et R²
#' @examples
#' deltaK <- c(10, 12, 15, 18, 22)
#' dadN <- c(1e-8, 2e-8, 5e-8, 1e-7, 3e-7)
#' fit_paris_law(deltaK, dadN)
#' @export
fit_paris_law <- function(deltaK, dadN) {
  log_deltaK <- log10(deltaK)
  log_dadN <- log10(dadN)
  
  fit <- lm(log_dadN ~ log_deltaK)
  
  C <- 10^coef(fit)[1]
  m <- coef(fit)[2]
  r_squared <- summary(fit)$r.squared
  
  list(
    C = C,
    m = m,
    r_squared = r_squared,
    model = fit
  )
}

#' Visualisation de la contrainte critique vs taille de fissure
#'
#' @param E Module d'Young (en GPa pour affichage)
#' @param gamma Energie de surface (en J/m²)
#' @param a_range Plage des tailles de fissure (en mm)
#' @param type Type de fissure
#' @return Objet ggplot
#' @examples
#' plot_griffith_curve(E = 70, gamma = 1)
#' @export
plot_griffith_curve <- function(E, gamma, a_range = c(0.1, 10), type = "internal") {
  E_si <- E * 1e9
  a_m <- seq(a_range[1] * 1e-3, a_range[2] * 1e-3, length.out = 100)
  
  sigma_c <- sapply(a_m, function(a) {
    sigma_critique(E = E_si, gamma = gamma, a = a, type = type)
  })
  
  df <- data.frame(
    crack_length_mm = a_m * 1000,
    critical_stress_MPa = sigma_c / 1e6
  )
  
  ggplot2::ggplot(df, ggplot2::aes(x = crack_length_mm, y = critical_stress_MPa)) +
    ggplot2::geom_line(color = "blue", linewidth = 1.2) +
    ggplot2::labs(
      title = "Courbe de Griffith",
      subtitle = sprintf("E = %g GPa, γ = %g J/m²", E, gamma),
      x = "Longueur de fissure (mm)",
      y = "Contrainte critique (MPa)"
    ) +
    ggplot2::theme_minimal()
}