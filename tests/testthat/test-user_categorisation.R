test_that("user_categorisation works with valid input", {
  # create a mock object that returns user inputs in sequence
  mock_readline <- mockery::mock("3", "This is a note", "n")
  # replace `readline` function within the `user_categorisation` function with
  # the `mock_readline` mock object
  mockery::stub(user_categorisation, "readline", mock_readline)

  response <- user_categorisation(var = "Variable1",
                                  desc = "Description1",
                                  type = "Type1", domain_code_max = 5)
  expect_equal(response, list(decision = "3", decision_note = "This is a note"))
})

test_that("user_categorisation handles invalid input and then valid input", {
  # create a mock object that returns invalid input first, then valid input
  mock_readline <- mockery::mock("6", "3", "This is a note", "n")
  # replace `readline` function within the `user_categorisation` function with
  # the `mock_readline` mock object
  mockery::stub(user_categorisation, "readline", mock_readline)

  response <- user_categorisation(var = "Variable1",
                                  desc = "Description1",
                                  type = "Type1", domain_code_max = 5)
  expect_equal(response, list(decision = "3", decision_note = "This is a note"))
})

test_that("user_categorisation handles multiple valid inputs", {
  # create a mock object that returns multiple valid inputs
  mock_readline <- mockery::mock("3,4", "This is another note", "n")
  # replace `readline` function within the `user_categorisation` function with
  # the `mock_readline` mock object
  mockery::stub(user_categorisation, "readline", mock_readline)

  response <- user_categorisation(var = "Variable1",
                                  desc = "Description1",
                                  type = "Type1", domain_code_max = 5)
  expect_equal(response, list(decision = "3,4",
                              decision_note = "This is another note"))
})

test_that("user_categorisation handles re-do input", {
  # create a mock object that returns inputs including re-do
  mock_readline <- mockery::mock("3", "This is a note", "y", "4",
                                 "Another note", "n")
  # replace `readline` function within the `user_categorisation` function with
  # the `mock_readline` mock object
  mockery::stub(user_categorisation, "readline", mock_readline)

  response <- user_categorisation(var = "Variable1",
                                  desc = "Description1",
                                  type = "Type1", domain_code_max = 5)
  expect_equal(response, list(decision = "4", decision_note = "Another note"))
})
