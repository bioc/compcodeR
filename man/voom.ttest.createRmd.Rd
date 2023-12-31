% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/generateRmdCodeDiffExp.R
\name{voom.ttest.createRmd}
\alias{voom.ttest.createRmd}
\title{Generate a \code{.Rmd} file containing code to perform differential expression analysis with voom+t-test}
\usage{
voom.ttest.createRmd(data.path, result.path, codefile, norm.method)
}
\arguments{
\item{data.path}{The path to a .rds file containing the \code{compData} object that will be used for the differential expression analysis.}

\item{result.path}{The path to the file where the result object will be saved.}

\item{codefile}{The path to the file where the code will be written.}

\item{norm.method}{The between-sample normalization method used to compensate for varying library sizes and composition in the differential expression analysis. The normalization factors are calculated using the \code{calcNormFactors} function from the \code{edgeR} package. Possible values are \code{"TMM"}, \code{"RLE"}, \code{"upperquartile"} and \code{"none"}.}
}
\value{
The function generates a \code{.Rmd} file containing the code for performing the differential expression analysis. This file can be executed using e.g. the \code{knitr} package.
}
\description{
A function to generate code that can be run to perform differential expression analysis of RNAseq data (comparing two conditions) by applying the voom transformation (from the \code{limma} package) followed by differential expression analysis with a t-test. The code is written to a \code{.Rmd} file. This function is generally not called by the user, the main interface for performing differential expression analysis is the \code{\link{runDiffExp}} function.
}
\details{
For more information about the methods and the interpretation of the parameters, see the \code{limma} and \code{edgeR} packages and the corresponding publications.
}
\examples{
try(
if (require(genefilter)) {
tmpdir <- normalizePath(tempdir(), winslash = "/")
mydata.obj <- generateSyntheticData(dataset = "mydata", n.vars = 1000,
                                    samples.per.cond = 5, n.diffexp = 100,
                                    output.file = file.path(tmpdir, "mydata.rds"))
runDiffExp(data.file = file.path(tmpdir, "mydata.rds"), result.extent = "voom.ttest",
           Rmdfunction = "voom.ttest.createRmd",
           output.directory = tmpdir, norm.method = "TMM")
})
}
\references{
Smyth GK (2005): Limma: linear models for microarray data. In: 'Bioinformatics and Computational Biology Solutions using R and Bioconductor'. R. Gentleman, V. Carey, S. Dudoit, R. Irizarry, W. Huber (eds), Springer, New York, pages 397-420

Law CW, Chen Y, Shi W and Smyth GK (2014): voom: precision weights unlock linear model analysis tools for RNA-seq read counts. Genome Biology 15, R29
}
\author{
Charlotte Soneson
}
