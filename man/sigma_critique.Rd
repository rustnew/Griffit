\name{sigma_critique}
\alias{sigma_critique}
\title{Contrainte Critique selon Griffith}
\description{Calcule la contrainte critique de propagation d'une fissure.}
\usage{
sigma_critique(E, gamma, a, type = "internal", nu = NULL)
}
\arguments{
  \item{E}{Module d'Young (Pa ou MPa)}
  \item{gamma}{Énergie de surface (J/m²)}
  \item{a}{Demi-longueur de fissure (m)}
  \item{type}{Type de fissure}
  \item{nu}{Coefficient de Poisson}
}
\value{Contrainte critique σ_c}
\examples{
sigma_critique(E = 70e9, gamma = 1, a = 0.001)
}