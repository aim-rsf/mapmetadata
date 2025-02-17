#' data_load
#'
#' Internal Function: Called within the metadata_map function. \cr \cr
#' Collects inputs needed for metadata_map function (defaults or user inputs)
#' If some inputs are NULL, it loads the default inputs. If defaults not
#' available, it prints error for the user.
#' If inputs are not NULL, it loads the user-specified inputs.
#' @param metadata_file As defined in metadata_map
#' @param domain_file As defined in metadata_map
#' @param look_up_file As defined in metadata_map
#' @param quiet Default is FALSE. Change to TRUE to quiet the cli_alert_info
#' and cli_alert_success messages.
#' @return A list of 6: all inputs needed for the metadata_map function to run.
#' @importFrom cli cli_alert_info
#' @importFrom utils read.csv
#' @importFrom tools file_path_sans_ext
#' @importFrom dplyr left_join
#' @keywords internal
#' @dev generate help files for unexported objects, for developers

data_load <- function(metadata_file, domain_file, look_up_file, quiet = FALSE) {

  ## Check that quiet is a boolean
  if (!is.logical(quiet)) {
    stop(paste("quiet should take the value of 'TRUE' or 'FALSE'"))
  }

  if (is.null(metadata_file) && is.null(domain_file)) {
    metadata <- get("metadata")
    metadata_desc <- "360_NCCHD"
    domains <- get("domain_list")
    domain_list_desc <- "DemoList"
    if (!quiet) {
      cli_alert_info("Running demo mode using package data files")
    }
    demo_mode <- TRUE
  } else if (is.null(metadata_file) && !is.null(domain_file) ||
               !is.null(metadata_file) && is.null(domain_file)) {
    stop("Provide both csv & domain file (or neither to run demo)")
  } else {
    # read in user specified files
    demo_mode <- FALSE
    metadata_base <- basename(metadata_file)

    # Verify the metadata file name pattern and that it is a .csv file
    if (!grepl("^[0-9]+_.*_Metadata\\.csv$", metadata_base) ||
          tools::file_ext(metadata_file) != "csv") {
      stop(paste("metadata_file name must be a .csv file in the format",
                 "ID_Name_Metadata.csv where ID is an integer"))
    } else {
      if (!file.exists(metadata_file)) {
        stop("metadata_file is the correct filename but it does not exist!")
      }
    }

    # Check if metadata column names match what is expected
    metadata <- read.csv(metadata_file)
    column_names <- colnames(metadata)
    expected_column_names <- c("Section", "Column.name", "Data.type",
                               "Column.description", "Sensitive")
    if (!identical(sort(column_names), sort(expected_column_names))) {
      stop("metadata_file does not have expected column names")
    }

    metadata_base_0suffix <- sub("_Metadata.csv$", "", metadata_base)
    metadata_desc <- gsub(" ", "", metadata_base_0suffix)

    # Check if the domain_file is a csv and has two columns
    if (file.exists(domain_file) && tools::file_ext(domain_file) == "csv") {
      domains <- read.csv(domain_file)
      column_names <- colnames(domains)
      expected_column_names <- c("Domain_Code", "Domain_Name")
      if (identical(sort(column_names), sort(expected_column_names))) {
        domain_list_desc <- file_path_sans_ext(basename(domain_file))
      } else {
        stop("domain_file does not have the expected column names")
      }
    } else {
      stop("domain_file does not exist or is not in csv format.")
    }
  }

  # Check the domain_file 'Code' column is correct
  code_expected <- as.integer(seq(1, nrow(domains), 1))
  if (!identical(code_expected, domains$Domain_Code)) {
    stop(paste("'Code' column in domain_file is not as expected.\n",
               "Expected 1:", nrow(domains)))
  }

  # Collect look up table
  if (is.null(look_up_file)) {
    if (!quiet) {
      cli_alert_info("Using the default look-up table in data/look-up.rda")
    }
    lookup <- get("look_up")
  } else {
    if (!quiet) {
      cli_alert_info("Using look up file inputted by user")
    }
    # Check look_up file given by user
    if (file.exists(look_up_file) && tools::file_ext(look_up_file) == "csv") {
      lookup <- read.csv(look_up_file)
      expected_column_names <- c("Variable", "Domain_Name")
      if (!all(colnames(lookup) == expected_column_names)) {
        stop("look_up file does not have expected column names")
      }
      # Add Domain_Code column into lookup table
      lookup <- lookup %>% left_join(domains, by = "Domain_Name")
      # Check for look_up rows not covered by domain_list
      no_match <- lookup[!lookup$Domain_Name %in% domains$Domain_Name, ]
      if (nrow(no_match) != 0) {
        warning(paste("There are domain names in the look_up_file that are not",
                      "included in the domain_file. If this is not expected,",
                      "check for mistakes."))
      }
    } else {
      stop("look_up_file does not exist or is not in csv format.")
    }
  }

  list(metadata = metadata,
       metadata_desc = metadata_desc,
       domains = domains,
       domain_list_desc = domain_list_desc,
       demo_mode = demo_mode,
       lookup = lookup)
}

#' output_copy
#'
#' Internal Function: Called within the metadata_map function. \cr \cr
#' Searches for previous OUTPUT files in the output_dir, that match the dataset
#' name. \cr \cr
#' If files exist, it removes duplicates and autos, and stores the rest of the
#' table variables in a dataframe. \cr \cr
#'
#' @param dataset_name Name of the dataset
#' @param output_dir Output directory to be searched
#' @param quiet Default is FALSE. Change to TRUE to quiet the cli_alert_info
#' and cli_alert_success messages.
#' @return It returns a list of 2: df_prev_exist (a boolean) and df_prev
#' (NULL or populated with table variables to copy)
#' @importFrom dplyr %>% distinct
#' @importFrom cli cli_alert_info
#' @keywords internal
#' @dev generate help files for unexported objects, for developers

output_copy <- function(dataset_name, output_dir, quiet = FALSE) {
  o_search <- paste0("^MAPPING_", gsub(" ", "", dataset_name), "*")
  csv_list <- data.frame(file = list.files(output_dir, pattern = o_search))
  if (nrow(csv_list) != 0) {
    df_list <- lapply(file.path(output_dir, csv_list$file), read.csv)
    df_prev <- do.call("rbind", df_list) # combine all df
    ## make a new date column, order by earliest, remove duplicates & auto
    df_prev$time2 <- as.POSIXct(df_prev$timestamp, format = "%Y-%m-%d-%H-%M-%S")
    df_prev <- df_prev[order(df_prev$time2), ]
    df_prev <- df_prev %>% distinct(variable, .keep_all = TRUE)
    df_prev <- df_prev[-(which(df_prev$note %in% "AUTO CATEGORISED")), ]
    df_prev_exist <- TRUE
    if (!quiet) {
      cli_alert_info(paste0("Copying from previous session(s):\n",
                            paste(csv_list$file, collapse = "\n"), "\n\n"))
    }
  } else {
    df_prev <- NULL
    df_prev_exist <- FALSE
  }

  copy_prev <- list(df_prev = df_prev, df_prev_exist = df_prev_exist)
  copy_prev
}
