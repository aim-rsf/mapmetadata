readline <- NULL
scan <- NULL

#' Internal: user_categorisation
#'
#' Internal Function: Called within the metadata_map function. \cr \cr
#' It displays data properties to the user and requests a categorisation into
#' a domain. \cr \cr
#' An optional note can be included with the categorisation.
#'
#' @param var Name of the variable
#' @param desc Description of the variable
#' @param type Data type of the variable
#' @param domain_code_max Max code in the domain list (0-3 auto included,
#' then N included via domain_file)
#' @return It returns a list containing the decision and decision note
#' @importFrom cli cli_alert_warning
#' @keywords internal
#' @dev generate help files for unexported objects, for developers

user_categorisation <- function(var, desc, type,
                                domain_code_max) {
  first_run <- TRUE
  go_back <- ""

  while (go_back == "Y" || go_back == "y" || first_run == TRUE) {
    go_back <- ""
    # print text to R console
    cat(paste(
      "\nVARIABLE -----> ", var,
      "\n\nDESCRIPTION -----> ", desc,
      "\n\nDATA TYPE -----> ", type, "\n\n"
    ))

    # ask user for categorisation:

    decision <- ""
    validated <- FALSE

    while (decision == "" || validated == FALSE) {
      decision <- readline(paste("Categorise variable into domain(s).",
                                 "E.g. 3 or 3,4: "))

      # validate input given by user
      decision_int <- as.integer(unlist(strsplit(decision, ",")))
      decision_int_na <- any(is.na((decision_int)))
      suppressWarnings(decision_int_max <- max(decision_int, na.rm = TRUE))
      suppressWarnings(decision_int_min <- min(decision_int, na.rm = TRUE))
      if (decision_int_na == TRUE || decision_int_max > domain_code_max ||
            decision_int_min < 0) {
        cli_alert_warning(paste("Formatting is invalid or integer out of",
                                "range. Provide one integer or a comma",
                                "seperated list of integers."))
        validated <- FALSE
      } else {
        validated <- TRUE
        # standardize output
        decision_int <- sort(decision_int)
        decision <- paste(decision_int, collapse = ",")
      }
    }

    # ask user for note on categorisation:

    decision_note <- readline(paste("Categorisation note (or press enter to",
                                    "continue): "))

    while (go_back != "Y" && go_back != "y" && go_back
           != "N" && go_back != "n") {
      go_back <- readline(prompt = paste("Response to be saved is '",
                                         decision,
                                         "'. Would you like to re-do?",
                                         "(y/n): "))
    }

    first_run <- FALSE
  }

  return(list(decision = decision, decision_note = decision_note))
}

#' Internal: user_categorisation_loop
#'
#' Internal Function: Called within the metadata_map function. \cr \cr
#' Given a specific table and a number of variables to search, it checks for
#' 3 different sources of domain categorisation: \cr \cr
#' 1 - If variables match look-up table, auto categorise \cr \cr
#' 2 - If variables match to previous table output, copy them \cr \cr
#' 3 - If no match for 1 or 2, variables are categorised by the user \cr \cr
#' @param start_v Index of variable to start
#' @param end_v Index of variables to end
#' @param table_df Dataframe with table info, extracted from metadata file
#' @param df_prev_exist Boolean to indicate if previous dataframes exists
#' @param df_prev Previous dataframes to copy from (or NULL)
#' @param lookup The lookup table to enable auto categorisations
#' @param n_codes Number of domain codes permissible
#' @param output_df Empty output dataframe, to fill
#' @param quiet Default is FALSE. Change to TRUE to quiet the cli_alert_info
#' and cli_alert_success messages.
#' @return An output dataframe containing info about the table, variables
#' and categorisations
#' @importFrom dplyr %>% add_row filter
#' @importFrom cli cli_alert_info
#' @keywords internal
#' @dev generate help files for unexported objects, for developers

user_categorisation_loop <- function(start_v, end_v, table_df, df_prev_exist,
                                     df_prev, lookup, n_codes, output_df,
                                     quiet = FALSE) {
  for (data_v in start_v:end_v) {
    if (!quiet) {
      cli_alert_info(paste0("Variable {data_v} of {nrow(table_df)} (",
                            length(data_v:end_v), " left to process)"))
    }
    this_variable <- table_df$Column.name[data_v]
    this_variable_n <- paste(
      as.character(data_v), "of",
      as.character(nrow(table_df))
    )

    ##### search if variable matches any variable from previous table
    if (df_prev_exist == TRUE) {
      data_v_index <- which(df_prev$var ==
                              table_df$Column.name[data_v])
      df_prev_subset <- df_prev[data_v_index, ]
    } else {
      df_prev_subset <- data.frame()
    }
    ##### decide how to process the variable out of 3 options:

    ###### 1 - auto categorisation via the lookup table
    lookup_variable <- filter(lookup, Variable == this_variable)
    if (nrow(lookup_variable) != 0) {
      output_df <- output_df %>% add_row(
        variable = this_variable,
        variable_n = this_variable_n,
        domain_code = as.character(lookup_variable$Domain_Code),
        note = "AUTO CATEGORISED"
      )
    } else if (df_prev_exist == TRUE &&
                 nrow(df_prev_subset) == 1) {
      ###### 2 - copy from previous table
      output_df <- output_df %>% add_row(
        variable = this_variable,
        variable_n = this_variable_n,
        domain_code = as.character(df_prev_subset$domain_code),
        note = paste0("COPIED FROM: ", df_prev_subset$table)
      )
    } else {
      ###### 3 - collect user responses with 'user_categorisation.R'
      decision_output <- user_categorisation(
        table_df$Column.name[data_v],
        table_df$Column.description[data_v],
        table_df$Data.type[data_v],
        n_codes
      )
      output_df <- output_df %>% add_row(
        variable = this_variable,
        variable_n = this_variable_n,
        domain_code = decision_output$decision,
        note = decision_output$decision_note
      )
    }
  } # end of loop for variable
  output_df
}
