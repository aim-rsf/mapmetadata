output_df <- get("output_df")

test_that("user_categorisation_loop handles auto categorisation", {
  # Mock data
  table_df <- data.frame(Column.name = c("Variable1", "Variable2"),
                         Column.description = c("Desc1", "Desc2"),
                         Data.type = c("Type1", "Type2"))
  lookup_joined <- data.frame(Variable = c("Variable1", "Variable2"),
                              Domain_Name = c("METADATA", "ID"),
                              Domain_Code = c(2, 3))

  n_codes <- 2

  # Call the function
  result <- user_categorisation_loop(1, 2, table_df, FALSE, data.frame(),
                                     lookup_joined, n_codes, output_df)

  # Check the result
  expect_equal(nrow(result), 2)
  expect_equal(result$note[1], "AUTO CATEGORISED")
  expect_equal(result$note[2], "AUTO CATEGORISED")
})

test_that("user_categorisation_loop handles copying from previous table", {
  # Mock data
  table_df <- data.frame(Column.name = c("Variable1", "Variable2"),
                         Column.description = c("Desc1", "Desc2"),
                         Data.type = c("Type1", "Type2"))
  df_prev <- data.frame(variable = c("Variable1", "Variable2"),
                        domain_code = c(1, 2), table = c("PrevTable1",
                                                         "PrevTable2"))

  lookup_joined <- data.frame(Variable = c("Variable3", "Variable4"),
                              Domain_Name = c("METADATA", "ID"),
                              Domain_Code = c(2, 3))

  # Call the function
  result <- user_categorisation_loop(1, 2, table_df, TRUE, df_prev,
                                     lookup_joined, df_plots, output_df)

  # Check the result
  expect_equal(nrow(result), 2)
  expect_equal(result$note[1], "COPIED FROM: PrevTable1")
  expect_equal(result$note[2], "COPIED FROM: PrevTable2")
})

test_that("user_categorisation_loop handles user categorisation", {
  # Mock data
  table_df <- data.frame(Column.name = c("Variable1", "Variable2"),
                         Column.description = c("Desc1", "Desc2"),
                         Data.type = c("Type1", "Type2"))

  lookup_joined <- data.frame(Variable = c("Variable3", "Variable4"),
                              Domain_Name = c("METADATA", "ID"),
                              Domain_Code = c(2, 3))

  # Mock the user_categorisation function
  local_mocked_bindings(user_categorisation = function(var = NULL,
                                                       desc = NULL,
                                                       type = NULL,
                                                       domain_code_max = NULL) {
    return(list(decision = "1", decision_note = "User note"))
  })

  # Call the function
  result <- user_categorisation_loop(1, 2, table_df, FALSE, data.frame(),
                                     lookup_joined, df_plots, output_df)

  # Check the result
  expect_equal(nrow(result), 2)
  expect_equal(result$note[1], "User note")
  expect_equal(result$domain_code[1], "1")
})
