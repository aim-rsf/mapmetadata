readline <- NULL
menu <- NULL
select.list <- NULL

#' metadata_map
#'
#' This function will read in the metadata file for a chosen dataset, loop
#' through all the data elements, and ask the user to map (to categorise) each
#' data element to one or more domains. The domains will appear
#' in the Plots tab for the user's reference. \cr \cr
#' These categorisations will be saved to a csv file, alongside a log file which
#' summarises the session details. To speed up this process, some
#' auto-categorisations will be made by the function for commonly occurring data
#' elements, and categorisations for the same data element can be copied from one
#' table to another. \cr \cr
#' Example inputs are provided within the package data, for the user to run this
#' function in a demo mode.
#' @param metadata_file This should be a csv download from HDRUK gateway
#' (0_Dataset_Structural_Metadata.csv). Default is 'data/metadata.rda' - run
#' '?metadata' to see how it was created.
#' @param domain_file This should be a csv file created by the user, with each
#' domain on a separate line, no header. Default is 'data/domain_list.rda'
#' - run '?domain_list' to see how it was created.
#' Note that 4 domains will be added automatically (NO MATCH/UNSURE, METADATA,
#' ID, DEMOGRAPHICS) and therefore should not be included in the domain_file.
#' @param look_up_file The lookup file makes auto-categorisations intended for
#' variables that appear regularly in health datasets. It only works for 1:1
#' mappings right now, i.e. DataElement should only be listed once in the file.
#' Default is 'data/look-up.rda' - run '?look_up' to see how it was created.
#' @param output_dir The path to the directory where the two csv output files
#' will be saved. Default is the current working directory.
#' @param table_copy Turn on copying between tables (default TRUE).
#' If TRUE, categorisations you made for all other tables in this dataset will
#' be copied over (if 'OUTPUT_' files are found in output_dir). This can be
#' useful when the same data elements (variables) appear across multiple
#' tables within one dataset; copying from one table to the next will save the
#' user time, and ensure consistency of categorisations across tables.
#' @param long_output Run map_convert.R to create a new longer output
#' 'L-OUTPUT_' which gives each categorisation its own row. Default is TRUE.
#' @return The function will return two csv files: 'OUTPUT_' which contains the
#' mappings and 'LOG_' which contains details about the dataset and session.
#' @examples
#' \dontrun{
#' # Demo run requires no function inputs but requires user interaction
#' metadata_map()
#' }
#' @export
#' @importFrom dplyr %>% filter
#' @importFrom cli cli_h1 cli_alert_info cli_alert_success
#' @importFrom utils packageVersion write.csv browseURL menu select.list
#' @importFrom ggplot2 ggsave
#' @importFrom htmlwidgets saveWidget

metadata_map <- function(
    metadata_file = NULL,
    domain_file = NULL,
    look_up_file = NULL,
    output_dir = getwd(),
    table_copy = TRUE,
    long_output = TRUE) {
  timestamp_now_fname <- format(Sys.time(), "%Y-%m-%d-%H-%M-%S")
  timestamp_now <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")

  # SECTION 1 - DEFINE & PREPARE INPUTS ----

  ## Use 'data_load.R' to collect inputs (defaults or user inputs)
  data <- data_load(metadata_file, domain_file, look_up_file)

  ## Extract Dataset from metadata_file
  dataset <- data$metadata
  dataset_name <- data$metadata_desc

  ## Convert the Section column to a factor
  dataset$Section <- as.factor(dataset$Section)

  ## Calculate the number of unique tables in the Section column
  n_tables <- length(levels(dataset$Section))

  ## Print info about dataset to user
  cli_alert_info("Processing dataset: {dataset_name}")
  cli_alert_info("There are {n_tables} tables in this dataset")

  # SECTION 2 - CREATE SUMMARY BAR PLOT FOR DATASET ----

  ## Use 'empty_count.R' to count empty variable descriptions
  empty_count_df <- empty_count(dataset)

  ## Use 'empty_plot.R' to create bar plot then save it
  bar_title <- paste0("\n'", dataset_name, "' contains ", n_tables, " table(s)")
  barplot_html <- empty_plot(empty_count_df, bar_title)
  original_wd <- getwd()
  setwd(output_dir) # saveWidget has a bug with paths & saving
  base_fname <- paste0(
    "BAR_", gsub(" ", "", dataset_name), "_",
    timestamp_now_fname
  )
  bar_fname <- paste0(base_fname, ".html")
  saveWidget(widget = barplot_html, file = bar_fname, selfcontained = TRUE)
  bar_data_fname <- paste0(base_fname, ".csv")
  write.csv(empty_count_df, bar_data_fname, row.names = FALSE)
  setwd(original_wd) # saveWidget has a bug with paths & saving

  ## Display outputs to the user
  cat("\n")
  browseURL(bar_fname)
  cli_alert_info("A bar plot should have opened in your browser. It has also been saved to your project directory (alongside a csv).")
  cli_alert_info("Use this bar plot, and the information on the HDRUK Gateway, to guide your mapping approach.")

  # SECTION 3 - MAPPING VARIABLES TO CONCEPTS (DOMAINS) FOR EACH TABLE ----

  cat("\n")
  readline("Press 'Esc' key to finish here, or press any other key to continue with mapping variables")

  ## Read in prepared output data frames
  log_output_df <- get("log_output_df")
  output_df <- get("output_df")

  ## Use 'ref_plot.R' to plot domains for the user's ref (save df for later use)
  df_plots <- ref_plot(data$domains)

  ## Check if look_up_file and domain_file are compatible
  mistmatch <- setdiff(data$lookup$domain_code, df_plots$code$code)
  if (length(mistmatch) > 0) {
    cli_alert_danger("The look_up_file and domain_file are not compatible. These look up codes are not listed in the domain codes:")
    cat("\n")
    print(mistmatch)
    stop()
  }

  ## Get user initials for the log file
  user_initials <- readline(prompt = "Enter your initials: ")

  ## CHOOSE TABLE TO PROCESS

  chosen_table_n <- menu(levels(dataset$Section), title = "Enter the table number you want to process:")
  table_name <- levels(dataset$Section)[chosen_table_n]
  cat("\n")
  cli_alert_info("Processing Table {chosen_table_n} of {n_tables} ({table_name})")
  cat("\n")

  #### Use 'output_copy.R' to copy from previous output(s) if they exist
  if (table_copy == TRUE) {
    copy_prev <- output_copy(dataset_name, output_dir)
    df_prev_exist <- copy_prev$df_prev_exist
    df_prev <- copy_prev$df_prev
  } else {
    df_prev_exist <- FALSE
  }

  table_note <- readline(paste(
    "Optional free text note about this table",
    "(or press enter to continue): "
  ))

  ####  Extract table from metadata
  table_df <- dataset %>% filter(Section == levels(dataset$Section)[chosen_table_n])

  #### If demo, only process the first 20 elements
  if (data$demo_mode == TRUE) {
    start_v <- 1
    end_v <- min(20, nrow(table_df))
  } else {
    start_v <- 1
    end_v <- nrow(table_df)
  }

  #### Use 'user_categorisation_loop.R' to copy or request from user

  output_df <- user_categorisation_loop(start_v,
    end_v,
    table_df,
    df_prev_exist,
    df_prev,
    lookup = data$lookup,
    df_plots,
    output_df
  )

  output_df$timestamp <- timestamp_now
  output_df$table <- table_name


  #### Review auto categorized data elements
  cat("\n")
  cli_alert_info("These are the auto categorised data elements:")
  cat("\n")
  output_auto <- subset(output_df, note == "AUTO CATEGORISED")
  output_auto <- output_auto[, c("data_element", "domain_code", "note")]
  print(output_auto, row.names = FALSE)

  auto_elements <- output_df$data_element[output_df$note == "AUTO CATEGORISED"]

  auto_row_names <- select.list(auto_elements,
    multiple = TRUE,
    title = "\nSelect those you want to manually edit:"
  )

  auto_row <- which(output_df$data_element %in% auto_row_names)

  if (length(auto_row) != 0) {
    for (data_v_auto in auto_row) {
      ##### collect user responses with with 'user_categorisation.R'
      decision_output <- user_categorisation(
        table_df$Column.name[data_v_auto],
        table_df$Column.description[data_v_auto],
        table_df$Data.type[data_v_auto],
        max(df_plots$code$code)
      )
      ##### input user responses into output
      output_df$domain_code[data_v_auto] <- decision_output$decision
      output_df$note[data_v_auto] <- decision_output$decision_note
    }
  }

  ### Review user categorized data elements (optional)
  cat("\n")
  review_cats <- menu(c("Yes", "No"), title = "\nWould you like to review your categorisations?")
  if (review_cats == 1) {
    output_not_auto <- subset(output_df, note != "AUTO CATEGORISED")
    output_not_auto["note (first 12 chars)"] <-
      substring(output_not_auto$note, 1, 11)
    cli_alert_info("These are the data elements you categorised:")
    cat("\n")
    print(output_not_auto[, c("data_element", "domain_code", "note (first 12 chars)")], row.names = FALSE)

    not_auto_elements <- output_df$data_element[output_df$note != "AUTO CATEGORISED"]

    not_auto_row_names <- select.list(not_auto_elements,
      multiple = TRUE,
      title = "\nSelect those you want to edit:"
    )

    not_auto_row <- which(output_df$data_element %in% not_auto_row_names)

    if (length(not_auto_row) != 0) {
      for (data_v_not_auto in not_auto_row) {
        #####  collect user responses with with 'user_categorisation.R'
        decision_output <- user_categorisation(
          table_df$Column.name[data_v_not_auto],
          table_df$Column.description[data_v_not_auto],
          table_df$Data.type[data_v_not_auto],
          max(df_plots$code$code)
        )
        ##### input user responses into output
        output_df$domain_code[data_v_not_auto] <- decision_output$decision
        output_df$note[data_v_not_auto] <- decision_output$decision_note
      }
    }
  }

  ### Fill in log output
  log_output_df$timestamp <- timestamp_now
  log_output_df$mapmetadata <- packageVersion("mapmetadata")
  log_output_df$initials <- user_initials
  log_output_df$domain_list_desc <- data$domain_list_desc
  log_output_df$dataset <- dataset_name
  log_output_df$table <- table_name
  log_output_df$table_note <- table_note

  ### Create output file names
  csv_fname <- paste0(
    "MAPPING_", gsub(" ", "", dataset_name), "_",
    gsub(" ", "", table_name), "_", timestamp_now_fname, ".csv"
  )

  csv_log_fname <- paste0(
    "MAPPING_LOG_", gsub(" ", "", dataset_name), "_",
    gsub(" ", "", table_name), "_",
    timestamp_now_fname, ".csv"
  )

  png_fname <- paste0(
    "MAPPING_PLOT_", gsub(" ", "", dataset_name), "_",
    gsub(" ", "", table_name), "_", timestamp_now_fname, ".png"
  )

  ### Save final categorisations for this Table
  write.csv(output_df, paste(output_dir, csv_fname, sep = "/"), row.names = FALSE)
  write.csv(log_output_df,
    paste(output_dir, csv_log_fname, sep = "/"),
    row.names = FALSE
  )
  cat("\n")
  cli_alert_success("Final categorisations saved as:\n{csv_fname}")
  cli_alert_success("Session log saved as:\n{csv_log_fname}")

  ### Create and save a summary plot
  end_plot_save <- end_plot(df = output_df, table_name, ref_table = df_plots$domain_table)
  ggsave(
    plot = end_plot_save,
    paste(output_dir, png_fname, sep = "/"),
    width = 14,
    height = 8,
    units = "in"
  )
  cli_alert_success("A summary plot has been saved:\n{png_fname}")

  ### Create long output
  if (long_output == TRUE) {
    map_convert(csv_fname, output_dir)
    cli_alert_success("Alternative format saved as:\nL-{csv_fname}")
  }
} # end of function
