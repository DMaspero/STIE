% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/update_morphology_parameter.R
\name{update_morphology_parameter}
\alias{update_morphology_parameter}
\title{update_morphology_parameter}
\usage{
update_morphology_parameter(PE_on_spot, PM_on_cell, cells_on_spot,
  features)
}
\arguments{
\item{PE_on_spot}{a matrix of cell type probabilities for each spot estimated from the spot gene expression, where the row is the spot and column is the cell type}

\item{PM_on_cell}{a matrix of cell type probabilities for each cell estimated from the cellular morphological features, where the row is the cell and column is the cell type}

\item{cells_on_spot}{a data frame representing the cells on spots along with the cellular morphological features, where "cell_id" represents the unique cell id and "spot" represents the uniqe spot id}

\item{features}{a vector of character values, representing the morphological features used in the STIE model}
}
\description{
update_morphology_parameter re-etimates the parameters for the cellular morphological model in STIE
}
\examples{


}
