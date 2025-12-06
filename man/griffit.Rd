\name{griffit-package}
\alias{griffit-package}
\alias{griffit}
\docType{package}
\title{
Modèle Griffith pour l'Analyse Spatiale et Temporelle
}
\description{
Implémentation du modèle Griffith pour l'analyse de données spatiales
et temporelles avec des méthodes d'estimation, validation et visualisation.
}
\details{
\tabular{ll}{
Package: \tab griffit\cr
Type: \tab Package\cr
Version: \tab 0.1.0\cr
Date: \tab 2024-01-01\cr
License: \tab MIT\cr
}
}
\author{
Prénom Nom <email@exemple.com>
}
\references{
Griffith, D. A. (2003). Spatial Autocorrelation and Spatial Filtering.
Springer-Verlag.
}
\keyword{ package }
\seealso{
\code{\link{griffit_model}}, \code{\link{griffit_diagnostic}}
}
\examples{
\dontrun{
# Simuler des données
data <- griffit_simulate(n = 100, p = 3)

# Estimer le modèle
model <- griffit_model(y ~ x1 + x2 + x3, data = data)

# Résumé
summary(model)

# Diagnostic
diag <- griffit_diagnostic(model)

# Prédiction
pred <- predict(model)

# Validation croisée
cv_result <- griffit_cv(y ~ x1 + x2 + x3, data = data)

# Sélection de variables
selection <- griffit_select(y ~ x1 + x2 + x3, data = data, criterion = "aic")
}
}