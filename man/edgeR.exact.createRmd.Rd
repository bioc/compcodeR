% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/generateRmdCodeDiffExp.R
\name{edgeR.exact.createRmd}
\alias{edgeR.exact.createRmd}
\title{Generate a \code{.Rmd} file containing code to perform differential expression analysis with the edgeR exact test}
\usage{
edgeR.exact.createRmd(
  data.path,
  result.path,
  codefile,
  norm.method,
  trend.method,
  disp.type
)
}
\arguments{
\item{data.path}{The path to a .rds file containing the \code{compData} object that will be used for the differential expression analysis.}

\item{result.path}{The path to the file where the result object will be saved.}

\item{codefile}{The path to the file where the code will be written.}

\item{norm.method}{The between-sample normalization method used to compensate for varying library sizes and composition in the differential expression analysis. Possible values are \code{"TMM"}, \code{"RLE"}, \code{"upperquartile"} and \code{"none"}.}

\item{trend.method}{The method used to estimate the trend in the mean-dispersion relationship. Possible values are \code{"none"}, \code{"movingave"} and \code{"loess"}}

\item{disp.type}{The type of dispersion estimate used. Possible values are \code{"common"}, \code{"trended"} and \code{"tagwise"}.}
}
\value{
The function generates a \code{.Rmd} file containing the code for performing the differential expression analysis. This file can be executed using e.g. the \code{knitr} package.
}
\description{
A function to generate code that can be run to perform differential expression analysis of RNAseq data (comparing two conditions) using the exact test functionality from the edgeR package. The code is written to a \code{.Rmd} file. This function is generally not called by the user, the main interface for performing differential expression analysis is the \code{\link{runDiffExp}} function.
}
\details{
For more information about the methods and the interpretation of the parameters, see the \code{edgeR} package and the corresponding publications.
}
\examples{
tmpdir <- normalizePath(tempdir(), winslash = "/")
mydata.obj <- generateSyntheticData(dataset = "mydata", n.vars = 1000,
                                    samples.per.cond = 5, n.diffexp = 100,
                                    output.file = file.path(tmpdir, "mydata.rds"))
runDiffExp(data.file = file.path(tmpdir, "mydata.rds"), result.extent = "edgeR.exact",
           Rmdfunction = "edgeR.exact.createRmd",
           output.directory = tmpdir, norm.method = "TMM",
           trend.method = "movingave", disp.type = "tagwise")
}
\references{
Robinson MD, McCarthy DJ and Smyth GK (2010): edgeR: a Bioconductor package for differential expression analysis of digital gene expression data. Bioinformatics 26, 139-140
}
\author{
Charlotte Soneson
}
