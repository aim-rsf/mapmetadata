readline <- NULL
menu <- NULL
select.list <- NULL

#' metadata_map
#'
#' This function will read in the metadata file for a chosen dataset and create
#' a summary plot. It will ask a user to select a table from this dataset to
#' process, and loop through all the variables in this table, asking the user to
#' map (categorise) each variable to one or more domains. The domains will
#' appear in the Plots tab for the user's reference. \cr \cr
#' These categorisations will be saved to a csv file, alongside a log file which
#' summarises the session details. To speed up this process, some
#' auto-categorisations will be made by the function for commonly occurring
#' variables, and categorisations for the same variable can be copied from one
#' table to another. \cr \cr
#' Example inputs are provided within the package data, for the user to run this
#' function in a demo mode. Refer to the package website for more guidance.
#' @param metadata_file This should be a csv download from HDRUK gateway
#' (in the form of ID_Dataset_Metadata.csv). Run '?mapmetadata::metadata' to
#' see how the metadata_file for the demo was created.
#' @param domain_file This should be a csv file created by the user, with two
#' columns (Domain_Code and Domain_Name). Run '?mapmetadata::domain_list' to
#' see how the domain_file for the demo was created.
#' @param look_up_file The lookup file makes auto-categorisations intended for
#' variables that appear regularly in health datasets. It only works for 1:1
#' mappings right now, i.e. variable should only be listed once in the file.
#' Run '?mapmetadata::look_up' to see how the default look_up was created.
#' @param output_dir The path to the directory where the two csv output files
#' will be saved. Default is the current working directory.
#' @param table_copy Turn on copying between tables (default TRUE).
#' If TRUE, categorisations you made for all other tables in this dataset will
#' be copied over (if 'OUTPUT_' files are found in output_dir). This can be
#' useful when the same variables appear across multiple tables within one
#' dataset; copying from one table to the next will save the user time, and
#' ensure consistency of categorisations across tables.
#' @param long_output Run map_convert.R to create a new longer output. Default
#' is TRUE.
#' @param demo_number How many table variables to loop through in the demo.
#' Default is 5.
#' 'L-OUTPUT_' which gives each categorisation its own row. Default is TRUE.
#' @param quiet Default is FALSE. Change to TRUE to quiet the cli_alert_info
#' and cli_alert_success messages.
#' @return A html plot summarising the dataset. Various csv and png outputs to
#' summarise the user's mapping session for a specific table in the dataset.
#' @examples
#' # Demo run requires no function inputs but requires user interaction.
#' # See package documentation to guide user inputs.
#' if(interactive()) {
#'     temp_output_dir <- tempdir()
#'     metadata_map(output_dir = temp_output_dir)
#' }
#' @export
#' @importFrom dplyr %>% filter
#' @importFrom cli cli_alert_info cli_alert_success
#' @importFrom utils packageVersion write.csv browseURL menu select.list
#' @importFrom ggplot2 ggsave
#' @importFrom htmlwidgets saveWidget
#' @importFrom gridExtra tableGrob grid.arrange
#' @importFrom graphics plot.new

metadata_map <- function(
    metadata_file = NULL,
    domain_file = NULL,
    look_up_file = NULL,
    output_dir = getwd(),
    table_copy = TRUE,
    long_output = TRUE,
    demo_number = 5,
    quiet = FALSE) {
  timestamp_now_fname <- format(Sys.time(), "%Y-%m-%d-%H-%M-%S")
  timestamp_now <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")

  # SECTION 0 - VALIDATE INPUTS ----
  # first three are validated in data_load function

  ## Check if output_dir exists
  if (!dir.exists(output_dir)) {
    stop("The output_dir does not exist.")
  }

  ## Check that table_copy, long_output and quiet are all booleans
  if (!is.logical(table_copy) || !is.logical(long_output)
      || !is.logical(quiet)) {
    stop(paste("table_copy, long_output and quiet should take the",
               "value of 'TRUE' or 'FALSE'"))
  }

  ## Check demo_number is >5 and is an integer
  if (!is.numeric(demo_number) || demo_number < 5 || demo_number %% 1 != 0) {
    stop("demo_number should be an integer of 5 or greater")
  }

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
  if (!quiet) {
    cli_alert_info(paste("Processing dataset '{dataset_name}' containing",
                         "{n_tables} tables\n\n"))
  }

  # SECTION 2 - CREATE SUMMARY BAR PLOT FOR DATASET ----

  ## Use 'empty_count.R' to count empty variable descriptions
  empty_count_df <- empty_count(dataset)

  ## Use 'empty_plot.R' to create bar plot then save it
  base_fname_notime <- paste0("BAR_", gsub(" ", "", dataset_name))
  base_fname <- paste0(base_fname_notime, "_", timestamp_now_fname)
  bar_fname <- paste0(base_fname, ".html")
  bar_data_fname <- paste0(base_fname, ".csv")

  existing_files <- list.files(output_dir,
                               pattern = paste0("^", base_fname_notime))

  if (length(existing_files) > 0) {
    cli_alert_warning(paste("A bar plot already exists for this dataset, saved",
                            "in your output directory.\nSkipping creation",
                            "of a new plot and opening existing plot.\n\n"))
  } else {
    bar_title <- paste0("\n'", dataset_name, "' contains ", n_tables,
                        " table(s)")
    barplot_html <- empty_plot(empty_count_df, bar_title)
    original_wd <- getwd()
    setwd(output_dir) # saveWidget has a bug with paths & saving
    saveWidget(widget = barplot_html, file = bar_fname, selfcontained = TRUE)
    write.csv(empty_count_df, bar_data_fname, row.names = FALSE)
    setwd(original_wd) # saveWidget has a bug with paths & saving
    ## Display outputs to the user
    browseURL(file.path(output_dir, bar_fname))
    if (!quiet) {
      cli_alert_info(paste("A bar plot should have opened in your browser",
                           "(also saved to your project directory).\n",
                           "Use this bar plot, and information on the HDRUK",
                           "Gateway, to guide your mapping approach.\n\n"))
    }
  }

  # SECTION 3 - MAPPING VARIABLES TO CONCEPTS (DOMAINS) FOR EACH TABLE ----

  ## Read in prepared output data frames
  log_output_df <- get("log_output_df")
  output_df <- get("output_df")

  ## Extract domains and plot for user's reference
  domain_table <- tableGrob(data$domains, rows = NULL)
  grid.arrange(domain_table, nrow = 1, ncol = 1)
  n_codes <- nrow(data$domains)

  ## CHOOSE TABLE TO PROCESS

  chosen_table_n <- menu(
                         levels(dataset$Section),
                         title = "Enter the table number you want to process:")
  table_name <- levels(dataset$Section)[chosen_table_n]
  if (!quiet) {
    cli_alert_info(paste("Processing Table {chosen_table_n} of {n_tables}",
                         "({table_name})\n\n"))
  }

  #### Use 'output_copy.R' to copy from previous output(s) if they exist
  if (table_copy == TRUE) {
    copy_prev <- output_copy(dataset_name, output_dir)
    df_prev_exist <- copy_prev$df_prev_exist
    df_prev <- copy_prev$df_prev
  } else {
    df_prev_exist <- FALSE
  }

  table_note <- readline(paste("Optional note about this table: "))

  ####  Extract table from metadata
  table_df <- dataset %>%
    filter(Section == levels(dataset$Section)[chosen_table_n])

  #### If demo, only process the first n variables (default n is 20)
  if (data$demo_mode == TRUE) {
    start_v <- 1
    end_v <- min(demo_number, nrow(table_df))
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
    n_codes,
    output_df
  )

  output_df$timestamp <- timestamp_now
  output_df$table <- table_name


  #### Review auto categorized table variables
  if (!quiet) {
    cli_alert_info("These are the auto categorised variables:\n\n")
  }
  output_auto <- subset(output_df, note == "AUTO CATEGORISED")
  output_auto <- output_auto[, c("variable", "domain_code", "note")]
  print(output_auto, row.names = FALSE)

  auto_variables <- output_df$variable[output_df$note == "AUTO CATEGORISED"]

  auto_row_names <- select.list(auto_variables,
    multiple = TRUE,
    title = "\nSelect those you want to manually edit:"
  )

  auto_row <- which(output_df$variable %in% auto_row_names)

  if (length(auto_row) != 0) {
    for (v_auto in auto_row) {
      ##### collect user responses with with 'user_categorisation.R'
      decision_output <- user_categorisation(
        table_df$Column.name[v_auto],
        table_df$Column.description[v_auto],
        table_df$Data.type[v_auto],
        n_codes
      )
      ##### input user responses into output
      output_df$domain_code[v_auto] <- decision_output$decision
      output_df$note[v_auto] <- decision_output$decision_note
    }
  }

  ### Review user categorized variables (optional)
  review_cats <- menu(c("Yes", "No"), title =
                        "\nWould you like to review your categorisations?")
  if (review_cats == 1) {
    output_not_auto <- subset(output_df, note != "AUTO CATEGORISED")
    output_not_auto["note (first 12 chars)"] <-
      substring(output_not_auto$note, 1, 11)
    if (!quiet) {
      cli_alert_info("These are the variables you categorised:\n")
    }
    print(output_not_auto[, c("variable", "domain_code",
                              "note (first 12 chars)")], row.names = FALSE)

    not_auto_variables <- output_df$variable[output_df$note
                                             != "AUTO CATEGORISED"]

    not_auto_row_names <- select.list(not_auto_variables,
      multiple = TRUE,
      title = "\nSelect those you want to edit:"
    )

    not_auto_row <- which(output_df$variable %in% not_auto_row_names)

    if (length(not_auto_row) != 0) {
      for (v_not_auto in not_auto_row) {
        #####  collect user responses with with 'user_categorisation.R'
        decision_output <- user_categorisation(
          table_df$Column.name[v_not_auto],
          table_df$Column.description[v_not_auto],
          table_df$Data.type[v_not_auto],
          n_codes
        )
        ##### input user responses into output
        output_df$domain_code[v_not_auto] <- decision_output$decision
        output_df$note[v_not_auto] <- decision_output$decision_note
      }
    }
  }

  ### Fill in log output
  log_output_df$timestamp <- timestamp_now
  log_output_df$mapmetadata <- packageVersion("mapmetadata")
  log_output_df$domain_list_desc <- data$domain_list_desc
  log_output_df$dataset <- dataset_name
  log_output_df$table <- table_name
  log_output_df$table_note <- table_note

  ### Create output file names
  csv_fname <- paste0("MAPPING_", gsub(" ", "", dataset_name), "_",
                      gsub(" ", "", table_name),
                      "_", timestamp_now_fname, ".csv")

  csv_path <- file.path(output_dir, paste0("MAPPING_",
                                           gsub(" ", "", dataset_name),
                                           "_", gsub(" ", "", table_name),
                                           "_", timestamp_now_fname, ".csv"))

  csv_log_path <- file.path(output_dir, paste0("MAPPING_LOG_",
                                               gsub(" ", "", dataset_name),
                                               "_", gsub(" ", "", table_name),
                                               "_", timestamp_now_fname,
                                               ".csv"))
  png_path <- file.path(output_dir, paste0("MAPPING_PLOT_",
                                           gsub(" ", "", dataset_name),
                                           "_", gsub(" ", "", table_name),
                                           "_", timestamp_now_fname, ".png"))

  ### Save final categorisations for this Table
  write.csv(output_df, csv_path, row.names = FALSE)
  write.csv(log_output_df, csv_log_path, row.names = FALSE)

  ### Create and save a summary plot
  end_plot_save <- end_plot(df = output_df, table_name,
                            ref_table = domain_table)
  ggsave(
    plot = end_plot_save,
    filename = png_path,
    width = 14,
    height = 8,
    units = "in"
  )

  if (!quiet) {
    cli_alert_success("Final categorisations saved to:\n{csv_path}")
    cli_alert_success("Session log saved to:\n{csv_log_path}")
    cli_alert_success("Summary plot saved to:\n{png_path}")
  }

  ### Create long output
  if (long_output == TRUE) {
    map_convert(csv_to_convert = csv_fname, csv_to_convert_dir = output_dir,
                quiet = quiet)
  }

} # end of function
