% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/inputs_collect.R
\name{output_copy}
\alias{output_copy}
\title{output_copy}
\usage{
output_copy(dataset_name, output_dir, quiet = FALSE)
}
\arguments{
\item{dataset_name}{Name of the dataset}

\item{output_dir}{Output directory to be searched}

\item{quiet}{Default is FALSE. Change to TRUE to quiet the cli_alert_info
and cli_alert_success messages.}
}
\value{
It returns a list of 2: df_prev_exist (a boolean) and df_prev
(NULL or populated with table variables to copy)
}
\description{
Internal Function: Called within the metadata_map function. \cr \cr
Searches for previous OUTPUT files in the output_dir, that match the dataset
name. \cr \cr
If files exist, it removes duplicates and autos, and stores the rest of the
table variables in a dataframe. \cr \cr
}
\keyword{internal}
\keyword{internal}
