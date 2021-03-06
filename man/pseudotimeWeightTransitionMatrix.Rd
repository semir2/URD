% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/diffusion.R
\name{pseudotimeWeightTransitionMatrix}
\alias{pseudotimeWeightTransitionMatrix}
\title{Weight transition matrix by pseudotime}
\usage{
pseudotimeWeightTransitionMatrix(object, pseudotime, x0 = NULL, k = NULL,
  logistic.params = NULL, pseudotime.direction = "<")
}
\arguments{
\item{object}{An URD object}

\item{pseudotime}{(Character) Name of pseudotime to use for biasing (i.e. a column name of \code{@pseudotime})}

\item{x0}{(Numeric) Inflection point of the logistic function (in terms of pseudotime difference). Can be left \code{NULL} if \code{logistic.params} is specified.}

\item{k}{(Numeric) Slope of the logistic function. Can be left \code{NULL} if \code{logistic.params} is specified.}

\item{logistic.params}{(List) Output from \code{\link{pseudotimeDetermineLogistic}} that specifies both \code{x0} and \code{k}.}

\item{pseudotime.direction}{(Character: ">" or "<") Which direction to bias the transition probabilities (\code{"<"} is default, which biases them to move toward cells with younger pseudotime.)}
}
\value{
Sparse Matrix (dgCMatrix) of transition probabilities, weighted by pseudotime
}
\description{
This takes the matrix of transition probabilities and biases them according to
the difference in pseudotime between each pair of cells. The parameters of the
logistic function can be manually chosen or determined using \code{\link{pseudotimeDetermineLogistic}}.
The biased transition matrix is used as input to \code{\link{simulateRandomWalk}} or
\code{\link{simulateRandomWalksFromTips}}.
}
\examples{
# Determine parameters of logistic function
diffusion.logistic <- pseudotimeDetermineLogistic(object, "pseudotime", optimal.cells.forward = 40, max.cells.back = 80, pseudotime.direction = "<", do.plot = T, print.values = T)

# Generate biased transition matrix
biased.tm <- pseudotimeWeightTransitionMatrix(object, pseudotime = "pseudotime", logistic.params = diffusion.logistic, pseudotime.direction = "<")

# Simulate random walks
these.walks <- simulateRandomWalk(start.cells = tip.10.cells, transition.matrix = biased.tm, end.cells = root.cells, n = 50000, end.visits = 1, verbose.freq = 2500, max.steps = 5000)

# Process walks into visitation frequency
object <- processRandomWalks(object, walks = these.walks, walks.name = "10", verbose = F)

}
