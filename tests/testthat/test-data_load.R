# Define file paths to demo data relative to the package directory
demo_metadata_file <- system.file("inputs/360_NCCHD_Metadata.csv",
                                  package = "mapmetadata")
look_up_file <- system.file("inputs/look_up.csv",
                            package = "mapmetadata")
demo_domain_file <- system.file("inputs/domain_list_demo.csv",
                                package = "mapmetadata")

# Define package demo data
data("metadata")
data("look_up")
data("domain_list")

test_that("data_load runs in demo mode when both csv_file and domain_file are
          NULL", {

            result <- data_load(NULL, NULL, NULL)
            expect_true(result$demo_mode)
            expect_equal(result$metadata, metadata)
            expect_equal(result$domains, domain_list)
            expect_equal(result$domain_list_desc, "DemoList")
          })

test_that("data_load reads user-specified files correctly", {
  result <- data_load(demo_metadata_file, demo_domain_file, NULL)
  expect_false(result$demo_mode)
  expect_true(is.list(result$metadata))
  expect_true(is.data.frame(result$domains))
  expect_equal(result$domain_list_desc,
               tools::file_path_sans_ext(basename(demo_domain_file)))
})

test_that("data_load uses default look-up table when look_up_file is NULL", {
  result <- data_load(demo_metadata_file, demo_domain_file, NULL)
  expect_equal(result$lookup, look_up)
})

test_that("data_load reads user-specified look-up table correctly", {
  result <- data_load(demo_metadata_file, demo_domain_file, look_up_file)
  expect_true(is.data.frame(result$lookup))
  expect_equal(nrow(result$lookup), nrow(utils::read.csv(look_up_file)))
})

test_that("data_load errors when quiet is not boolean", {
  expect_error(data_load(NULL, NULL, NULL, quiet = "not valid"),
               "quiet should take the value of 'TRUE' or 'FALSE'")
})

test_that("data_load errors when  metadata_file is incorrect format", {
  expect_error(data_load(metadata_file = "Metadata_360NCCHD.csv",
                         demo_domain_file),
               paste("metadata_file name must be a .csv file in the format",
                     "ID_Name_Metadata.csv where ID is an integer"))
})

test_that("data_load errors when metadata_file does not exist", {
  expect_error(data_load(metadata_file = "360_NCCHD_Metadata.csv",
                         demo_domain_file),
               "metadata_file is the correct filename but it does not exist!")
})

test_that("data_load errors when metadata_file has incorrect column names", {
  metadata_temp <- metadata
  colnames(metadata_temp) <- c("a", "b", "c", "d", "e")
  temp_dir <- withr::local_tempdir()
  metadata_temp_file <- paste0(temp_dir, "/1_temp_Metadata.csv")
  write.csv(metadata_temp, file = metadata_temp_file, row.names = FALSE)
  expect_error(data_load(metadata_temp_file, demo_domain_file),
               "metadata_file does not have expected column names")
})

test_that("data_load errors when domain_file does not exist", {
  expect_error(data_load(demo_metadata_file, domain_file = "not valid"),
               "domain_file does not exist or is not in csv format.")
})

test_that("data_load errors when domain_file has incorrect column names", {
  domains_temp <- domain_list
  colnames(domains_temp) <- c("a", "b")
  temp_dir <- withr::local_tempdir()
  domain_file_temp <- paste0(temp_dir, "/domain_file_temp.csv")
  write.csv(domains_temp, file = domain_file_temp, row.names = FALSE)
  expect_error(data_load(demo_metadata_file, domain_file_temp),
               "domain_file does not have the expected column names")
})

test_that("data_load errors when domain_file 'Code' column not as expected", {
  domains_temp2 <- domain_list
  domains_temp2$Domain_Code[nrow(domain_list)] <-
    domains_temp2$Domain_Code[nrow(domains_temp2)] + 1
  temp_dir <- withr::local_tempdir()
  domain_file_temp2 <- paste0(temp_dir, "/domain_file_temp2.csv")
  write.csv(domains_temp2, file = domain_file_temp2, row.names = FALSE)
  expect_error(data_load(demo_metadata_file, domain_file_temp2),
               paste("'Code' column in domain_file is not as expected.\n",
                     "Expected 1:", nrow(domain_list)))
})

test_that("data_load errors when look_up_file does not exist", {
  expect_error(data_load(demo_metadata_file, demo_domain_file,
                         look_up_file = "not valid"),
               "look_up_file does not exist or is not in csv format.")
})

test_that("data_load errors when look_up_file has incorrect column names", {
  look_up_temp <- look_up
  colnames(look_up_temp) <- c("a", "b")
  temp_dir <- withr::local_tempdir()
  look_up_file_temp <- paste0(temp_dir, "/look_up_temp.csv")
  write.csv(look_up_temp, file = look_up_file_temp, row.names = FALSE)
  expect_error(data_load(demo_metadata_file, demo_domain_file,
                         look_up_file_temp),
               "look_up file does not have expected column names")
})

test_that("data_load gives warning when look_up and domain_file mistmatch", {
  look_up_temp2 <- look_up
  look_up_row <- data.frame(Variable = "test", Domain_Name = "test")
  look_up_temp2 <- rbind(look_up_temp2, look_up_row)
  temp_dir <- withr::local_tempdir()
  look_up_file_temp2 <- paste0(temp_dir, "/look_up_temp2.csv")
  write.csv(look_up_temp2, file = look_up_file_temp2, row.names = FALSE)

  expect_warning(
    data_load(demo_metadata_file, demo_domain_file, look_up_file_temp2),
    paste("There are domain names in the look_up_file that are not included",
          "in the domain_file. If this is not expected, check for mistakes.")
  )
})
