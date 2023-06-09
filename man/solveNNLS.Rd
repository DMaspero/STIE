% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/solveNNLS.R
\name{solveNNLS}
\alias{solveNNLS}
\title{solveNNLS}
\usage{
solveNNLS(S, B, scaled = T)
}
\arguments{
\item{S}{a matrix of cell type transcriptomic signature with row representing the gene and column representing the cell type}

\item{B}{a vector of bulk gene expression with row representing the gene and column representing the sample}

\item{scaled}{a boolean value indicating whether to scale the sum of cell type proportions to be 1}
}
\value{
a vector of non-negative regression coefficients on cell type transcriptomic signatures
}
\description{
solveNNLS solves the linear regression model with non-negative regression coefficients
}
\examples{


}
