# Package Griffith pour l'Analyse Spatiale

## 📋 Vue d'ensemble

**Griffit** est un package R professionnel implémentant le modèle Griffith pour l'analyse de données spatiales et temporelles. Il fournit des méthodes d'estimation robustes, des outils de diagnostic complets et des fonctions de visualisation pour l'analyse spatiale avancée.

## 🎯 Objectifs du Package

Ce package a été développé pour:
- Implémenter les modèles d'analyse spatiale de Griffith
- Fournir des méthodes d'estimation fiables (ML, GLS)
- Offrir des outils de validation et de diagnostic complets
- Faciliter l'analyse et l'interprétation des données spatiales
- Être modulaire et extensible pour la recherche

## 📊 Fonctionnalités Principales

### 1. **Estimation du Modèle**
- Estimation par Maximum de Vraisemblance (ML)
- Estimation par Moindres Carrés Généralisés (GLS)
- Calcul automatique des intervalles de confiance
- Mesures de qualité d'ajustement (AIC, BIC, log-vraisemblance)

### 2. **Diagnostic et Validation**
- Tests de normalité des résidus
- Tests d'autocorrélation spatiale
- Tests d'hétéroscédasticité
- Validation croisée intégrée
- Sélection de variables automatisée

### 3. **Simulation et Prédiction**
- Génération de données simulées selon le modèle Griffith
- Prédictions avec intervalles de confiance
- Simulation avec différents niveaux de corrélation spatiale

### 4. **Visualisation**
- Graphiques des résidus (QQ-plot, résidus vs valeurs ajustées)
- Visualisation des prédictions
- Diagrammes diagnostiques complets

## 🏗️ Structure du Package

```
Griffit/
├── DESCRIPTION           # Métadonnées du package
├── NAMESPACE            # Exports des fonctions
├── R/
│   └── griffit.R        # Code source principal (toutes les fonctions)
├── tests/
│   └── test_griffit.R   # Tests unitaires
└── man/
    ├── griffit-package.Rd  # Documentation du package
    └── griffit_function.Rd # Documentation des fonctions
```

## 📦 Installation

### Depuis GitHub (Recommandé)
```r
# Installation avec devtools
install.packages("devtools")
devtools::install_github("votrecompte/griffit")
```

### Installation Locale
```r
# Cloner le dépôt
git clone https://github.com/votrecompte/griffit.git

# Installer depuis le répertoire local
devtools::install("~/chemin/vers/griffit")
```

## 🚀 Utilisation Rapide

### 1. Chargement du Package
```r
library(griffit)
```

### 2. Simulation de Données
```r
# Générer des données simulées
set.seed(123)
sim_data <- griffit_simulate(
  n = 100,           # 100 observations
  p = 3,             # 3 variables explicatives
  sigma = 1,         # Écart-type des erreurs
  spatial_corr = 0.5, # Corrélation spatiale modérée
  seed = 123         # Reproductibilité
)

# Aperçu des données
head(sim_data)
str(sim_data)
```

### 3. Estimation du Modèle
```r
# Estimation par maximum de vraisemblance
model_ml <- griffit_model(
  y ~ x1 + x2 + x3,    # Formule du modèle
  data = sim_data,     # Données
  method = "ml",       # Méthode d'estimation
  control = list(      # Paramètres de contrôle
    maxit = 200,
    tol = 1e-6
  )
)

# Affichage des résultats
print(model_ml)
summary(model_ml)
```

### 4. Diagnostic du Modèle
```r
# Test de normalité des résidus
diag_residuals <- griffit_diagnostic(
  model_ml,
  test = "residuals"
)

# Test d'autocorrélation
diag_autocorr <- griffit_diagnostic(
  model_ml,
  test = "autocorrelation",
  lag = 1
)

# Test d'hétéroscédasticité
diag_hetero <- griffit_diagnostic(
  model_ml,
  test = "heteroscedasticity"
)

# Affichage des diagnostics
print(diag_residuals)
print(diag_autocorr)
print(diag_hetero)
```

### 5. Visualisation
```r
# Graphique des résidus
plot(model_ml, type = "residuals")

# QQ-plot
plot(model_ml, type = "qq")

# Résidus vs valeurs ajustées
plot(model_ml, type = "fitted")
```

### 6. Prédictions
```r
# Prédictions sur les mêmes données
predictions <- predict(model_ml)

# Prédictions avec intervalles de confiance
predictions_ci <- predict(
  model_ml,
  interval = "confidence",
  level = 0.95
)

# Prédictions avec intervalles de prédiction
predictions_pi <- predict(
  model_ml,
  interval = "prediction",
  level = 0.95
)

# Afficher les premières prédictions
head(predictions$fit)
head(predictions_ci$lower)
head(predictions_ci$upper)
```

### 7. Validation Croisée
```r
# Validation croisée à 5 folds
cv_result <- griffit_cv(
  y ~ x1 + x2 + x3,
  data = sim_data,
  folds = 5,
  method = "ml"
)

# Résultats de la validation croisée
print(cv_result)
cat("Erreur CV moyenne:", cv_result$mean_cv_error, "\n")
cat("Écart-type CV:", cv_result$sd_cv_error, "\n")
```

### 8. Sélection de Variables
```r
# Sélection backward avec critère AIC
selection <- griffit_select(
  y ~ x1 + x2 + x3,
  data = sim_data,
  criterion = "aic",
  direction = "backward"
)

# Afficher les résultats de sélection
print(selection)

# Meilleur modèle
best_model <- selection$selection_results[selection$best_model, ]
cat("Meilleur modèle:", best_model$variables, "\n")
cat("AIC:", best_model$criterion, "\n")
```

## 📚 Fonctions Disponibles

### Fonctions Principales
1. **`griffit_model()`** - Estimation du modèle principal
2. **`griffit_diagnostic()`** - Tests de diagnostic
3. **`predict.GriffitModel()`** - Prédictions
4. **`griffit_cv()`** - Validation croisée
5. **`griffit_simulate()`** - Simulation de données
6. **`griffit_select()`** - Sélection de variables

### Méthodes S3
- **`print.GriffitModel()`** - Affichage du modèle
- **`summary.GriffitModel()`** - Résumé statistique
- **`plot.GriffitModel()`** - Visualisation
- **`coef.GriffitModel()`** - Extraction des coefficients
- **`residuals.GriffitModel()`** - Extraction des résidus
- **`fitted.GriffitModel()`** - Extraction des valeurs ajustées
- **`logLik.GriffitModel()`** - Log-vraisemblance
- **`AIC.GriffitModel()`** - Critère AIC
- **`BIC.GriffitModel()`** - Critère BIC

## 🧪 Tests Unitaires

Le package inclut une suite complète de tests unitaires:

```r
# Exécuter tous les tests
devtools::test()

# Tests spécifiques
testthat::test_file("tests/test_griffit.R")
```

### Couverture des Tests
1. **Création du modèle** - Vérifie la création correcte des objets
2. **Résumé du modèle** - Teste les méthodes summary
3. **Diagnostic** - Valide les tests de diagnostic
4. **Prédiction** - Teste les fonctions de prédiction
5. **Simulation** - Vérifie la génération de données
6. **Validation croisée** - Teste la validation croisée

## 🔧 Développement

### Structure des Objets

Le package utilise une classe S4 pour représenter les modèles:

```r
# Structure de la classe GriffithModel
setClass("GriffitModel",
  slots = list(
    coefficients = "numeric",    # Coefficients estimés
    residuals = "numeric",       # Résidus
    fitted.values = "numeric",   # Valeurs ajustées
    variance = "matrix",         # Matrice de variance-covariance
    loglikelihood = "numeric",   # Log-vraisemblance
    aic = "numeric",            # Critère AIC
    bic = "numeric",            # Critère BIC
    convergence = "logical",    # État de convergence
    iterations = "numeric",     # Nombre d'itérations
    call = "call"              # Appel de la fonction
  )
)
```

### Extensibilité

Le package est conçu pour être extensible:

```r
# Ajouter une nouvelle méthode d'estimation
estimate_custom <- function(y, X, weights, control) {
  # Implémentation personnalisée
  # ...
}

# Créer une nouvelle classe dérivée
setClass("ExtendedGriffitModel",
  contains = "GriffitModel",
  slots = list(
    spatial_weights = "matrix",
    moran_i = "numeric"
  )
)
```

## 📈 Cas d'Utilisation

### 1. Analyse Spatiale en Économétrie
```r
# Données économiques spatiales
eco_data <- read.csv("donnees_economiques.csv")

# Modèle avec effets spatiaux
model_eco <- griffit_model(
  croissance ~ investissement + education + distance,
  data = eco_data,
  method = "ml"
)

# Diagnostic spatial
diag_spatial <- griffit_diagnostic(
  model_eco,
  test = "autocorrelation",
  lag = 2
)

# Visualisation
plot(model_eco, type = "residuals")
```

### 2. Étude Environnementale
```r
# Données de pollution
pollution_data <- read.csv("donnees_pollution.csv")

# Modèle avec validation croisée
cv_pollution <- griffit_cv(
  pollution ~ industrie + traffic + vegetation,
  data = pollution_data,
  folds = 10
)

# Sélection de variables optimales
selection_pollution <- griffit_select(
  pollution ~ industrie + traffic + vegetation + altitude + temperature,
  data = pollution_data,
  criterion = "bic"
)
```

### 3. Recherche Académique
```r
# Simulation pour étude de puissance
sim_study <- function(n_samples, n_vars) {
  results <- list()
  
  for (i in seq_along(n_samples)) {
    # Génération de données
    sim_data <- griffit_simulate(
      n = n_samples[i],
      p = n_vars[i]
    )
    
    # Estimation du modèle
    model <- griffit_model(
      y ~ .,
      data = sim_data
    )
    
    # Stockage des résultats
    results[[i]] <- list(
      n = n_samples[i],
      p = n_vars[i],
      coefficients = coef(model),
      aic = AIC(model),
      bic = BIC(model)
    )
  }
  
  return(results)
}
```

## 🛠️ Dépendances

### Imports (Obligatoires)
- **stats** - Fonctions statistiques de base
- **graphics** - Système de graphiques
- **grDevices** - Dispositifs graphiques
- **Matrix** - Manipulation de matrices

### Suggests (Optionnelles)
- **testthat** - Tests unitaires
- **knitr** - Génération de rapports
- **rmarkdown** - Documents dynamiques
- **covr** - Couverture de code

## 📝 Documentation

### Documentation R
```r
# Afficher l'aide d'une fonction
?griffit_model
?griffit_diagnostic
?griffit_simulate

# Liste toutes les fonctions
help(package = "griffit")
```

### Documentation en Ligne
- **README** - Ce fichier
- **Vignettes** - Tutoriels détaillés (à venir)
- **Site web** - Documentation complète (à venir)

## 🔍 Contrôle de Qualité

### Vérification du Package
```r
# Vérification complète
devtools::check()

# Vérification des dépendances
devtools::check_deps()

# Test de construction
devtools::build()
```

### Standards de Code
- Conformité aux standards du tidyverse
- Documentation roxygen2 complète
- Tests unitaires exhaustifs
- Gestion d'erreurs robuste

## 🤝 Contribution

### Signalement de Bugs
1. Vérifier si le bug existe déjà dans les issues
2. Créer une issue avec un exemple reproductible
3. Inclure la version du package et de R

### Suggestions d'Améliorations
1. Proposer des nouvelles fonctionnalités
2. Soumettre des corrections
3. Améliorer la documentation

### Développement
```bash
# Fork du dépôt
git clone https://github.com/votrecompte/griffit.git
cd griffit

# Créer une branche
git checkout -b nouvelle-fonctionnalite

# Installer en mode développement
devtools::load_all()
devtools::document()

# Exécuter les tests
devtools::test()

# Soumettre une pull request
```

## 📄 Licence

Ce package est distribué sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 📚 Références

### Publications Fondamentales
- Griffith, D. A. (2003). *Spatial Autocorrelation and Spatial Filtering*
- Anselin, L. (1988). *Spatial Econometrics: Methods and Models*

### Ressources Complémentaires
- R Spatial Task View
- CRAN Package: spdep
- CRAN Package: spatialreg

## 📞 Support

### Questions et Aide
- Issues GitHub pour les bugs
- Discussions GitHub pour les questions
- Email: votre@email.com

### Formation
- Tutoriels détaillés (à venir)
- Workshops (à venir)
- Documentation avancée (à venir)

## 📊 Exemples Avancés

### Analyse Comparative
```r
# Comparaison de méthodes d'estimation
data <- griffit_simulate(n = 200, p = 4)

# Estimation ML
model_ml <- griffit_model(y ~ ., data = data, method = "ml")

# Estimation GLS
model_gls <- griffit_model(y ~ ., data = data, method = "gls")

# Comparaison
comparison <- data.frame(
  Method = c("ML", "GLS"),
  AIC = c(AIC(model_ml), AIC(model_gls)),
  BIC = c(BIC(model_ml), BIC(model_gls)),
  LogLik = c(logLik(model_ml), logLik(model_gls))
)

print(comparison)
```

### Analyse de Sensibilité
```r
# Étude de sensibilité aux paramètres
sensitivity_analysis <- function(corr_values) {
  results <- list()
  
  for (corr in corr_values) {
    # Simulation avec différents niveaux de corrélation
    sim_data <- griffit_simulate(
      n = 100,
      p = 3,
      spatial_corr = corr,
      seed = 123
    )
    
    # Estimation
    model <- griffit_model(y ~ ., data = sim_data)
    
    # Stockage
    results[[as.character(corr)]] <- list(
      correlation = corr,
      coefficients = coef(model),
      standard_errors = sqrt(diag(vcov(model))),
      aic = AIC(model)
    )
  }
  
  return(results)
}

# Exécuter l'analyse
corr_range <- seq(0, 0.9, 0.1)
sens_results <- sensitivity_analysis(corr_range)
```

---

**Dernière mise à jour**: Janvier 2024  
**Version**: 0.1.0  
**Auteur**: Votre Nom  
**Contact**: votre@email.com  
**Site web**: https://github.com/votrecompte/griffit  

*Note: Ce package est en développement actif. Les fonctionnalités peuvent évoluer.*
