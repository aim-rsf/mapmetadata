% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/map_compare.R
\name{map_compare}
\alias{map_compare}
\title{map_compare}
\usage{
map_compare(
  session_dir,
  session1_base,
  session2_base,
  metadata_file,
  domain_file,
  output_dir = session_dir,
  quiet = FALSE
)
}
\arguments{
\item{session_dir}{This directory should contain 2 csv files for each session
(LOG_ and OUTPUT_), 4 csv files in total.}

\item{session1_base}{Base file name for session 1, see Example below.}

\item{session2_base}{Base file name for session 2, see Example below.}

\item{metadata_file}{The full path to the metadata file used when running
metadata_map (should be the same for session 1 and session 2)}

\item{domain_file}{The full path to the domain file used when running
metadata_map (should be the same for session 1 and session 2)}

\item{output_dir}{The path to the directory where the consensus output file
will be saved. By default, the session_dir is used.}

\item{quiet}{Default is FALSE. Change to TRUE to quiet the cli_alert_info
and cli_alert_success messages.}
}
\value{
It returns a csv output, which represents the consensus decisions
between session 1 and session 2
}
\description{
This function is to be used after running the metadata_map function. \cr \cr
It compares csv outputs from two sessions, finds their differences,
and asks for a consensus. \cr \cr
}
\examples{
# Demo run requires no function inputs but requires user interaction.
# See package documentation to guide user inputs.
if(interactive()) {
    temp_output_dir <- tempdir()
    # Locate file paths for the example files in the package
    demo_session_dir <- system.file("outputs", package = "mapmetadata")
    demo_session1_base <- "360_NCCHD_CHILD_2025-02-14-18-14-01"
    demo_session2_base <- "360_NCCHD_CHILD_2025-02-14-18-17-47"
    demo_metadata_file <- system.file("inputs","360_NCCHD_Metadata.csv",
    package = "mapmetadata")
    demo_domain_file <- system.file("inputs","domain_list_demo.csv",
    package = "mapmetadata")

    map_compare(
    session_dir = demo_session_dir,
    session1_base = demo_session1_base,
    session2_base = demo_session2_base,
    metadata_file = demo_metadata_file,
    domain_file = demo_domain_file,
    output_dir = temp_output_dir
    )}
}
