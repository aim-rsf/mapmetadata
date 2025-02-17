#' Internal: Output dataframe
#'
#' Internal Dataset: Empty output dataframe for metadata_map to fill.
#' Created by: \cr \cr
#' \enumerate{
#'  \item \code{output_df <- data.frame(timestamp = character(0),
#'  table = character(0),
#'  variable_n = character(0),
#'  variable = character(0),
#'  domain_code = character(0),
#'  note = character(0))}
#'  \item \code{usethis::use_data(output_df)}
#' }
#'
#' @docType data
#
#' @usage data(output_df)
#'
#' @keywords internal
#'
#' @format A data frame with 0 rows and 6 columns
#'
#' @source Dataframe was manually created as package data, using the above code.
"output_df"

#' Internal: Output log dataframe
#'
#' Internal Dataset: Empty log output dataframe for metadata_map to fill.
#' Created by: \cr \cr
#' \enumerate{
#'  \item \code{log_output_df <- data.frame(timestamp = character(1),
#'  mapmetadata = character(1),
#'  domain_list_desc = character(1),
#'  dataset = character(1),
#'  table = character(1),
#'  table_note = character(1))}
#'  \item \code{usethis::use_data(log_output_df)}
#' }
#'
#' @docType data
#
#' @usage data(log_output_df)
#'
#' @keywords internal
#'
#' @format A data frame with 1 empty row and 9 columns
#'
#' @source Dataframe was manually created as package data, using the above code.
"log_output_df"

#' Internal: List of Domains
#'
#' Internal Dataset: A simplified list of domains, to demo the function
#' metadata_map \cr \cr
#' This data was created with these two steps:
#' \enumerate{
#'  \item \code{domain_list <- read.csv(system.file('inputs',
#'  'domain_list_demo.csv', package = 'mapmetadata'))}
#'  \item \code{usethis::use_data(domain_list)}
#' }
#' @docType data
#
#' @usage data(domain_list)
#'
#' @keywords internal
#'
#' @format A data frame with 8 rows and 2 columns
#'
#' @source The csv was manually created
"domain_list"

#' Internal: CSV metadata File
#'
#' Example metadata for a health dataset, to demo metadata_map \cr \cr
#' This data was created with these steps:
#' \enumerate{
#'   \item Go to https://healthdatagateway.org
#'   \item Navigate to the dataset of interest, select 'Download data' and
#'   download the Structural Metadata file
#'   \item Shorten name of downloaded file e.g. 360_NCCHD_Metadata.csv
#'   \item \code{metadata <- read.csv(system.file('inputs',
#'   '360_NCCHD_Metadata.csv', package = 'mapmetadata'))}
#'   \item \code{usethis::use_data(metadata)}
#' }
#'
#' @docType data
#
#' @usage data(metadata)
#'
#' @keywords internal
#'
#' @format Nested lists
#'
#' @source https://healthdatagateway.org/en/dataset/360
"metadata"

#' Internal: Auto-categorisations
#'
#' Pre-defined pairings between table variables and domain codes. \cr \cr
#' For each variable that metadata_map processes: \cr \cr
#' If it is contained within this look-up table, it uses the auto-categorised
#' domain code rather than asking the user to categorise.\cr\cr
#' This data was created with these two steps:
#' \enumerate{
#'  \item \code{look_up <- read.csv(system.file('inputs',
#'  'look_up.csv',package = 'mapmetadata'))}
#'  \item \code{usethis::use_data(look_up)}
#' }
#' @docType data
#
#' @usage data(look_up)
#'
#' @keywords internal
#'
#' @format A data frame with a variable number of rows and 2 columns
#'
#' @source The csv was manually created
"look_up"
