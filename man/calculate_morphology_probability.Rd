% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/calculate_morphology_probability.R
\name{calculate_morphology_probability}
\alias{calculate_morphology_probability}
\title{calculate_morphology_probability}
\usage{
calculate_morphology_probability(morphology_features, feature_list, mu,
  sigma, scaled = TRUE)
}
\arguments{
\item{morphology_features}{a matrix of numeric values in the size of cells X features, representing the values of morphology_features for each cell, where the column names are the morphoglical features, and row names are cell ids}

\item{feature_list}{a vector of characters representing the names of morphology features used in the STIE model}

\item{mu}{a vector of numeric values representing the mean of morphological features under normal distribution}

\item{sigma}{a vector of numeric values representing the standard deviation of morphological features under normal distribution}

\item{scaled}{boolean value representing whether the sum of probability is scaled to be 1}
}
\value{
a matrix of numeric values in size of cells X features representing the values of morphology feature probability for each cell
}
\description{
calculate_morphology_probability calculates the morphological probability by assuming the normal distribution with parameters mu and sigma
}
\examples{
# 



}
\references{

}
\seealso{
\code{\link{update_morphology_parameter}}; \code{\link{get_cells_on_spot}};
}
\author{
Shijia Zhu, \email{shijia.zhu@UTsouthwestern.edu}
}
