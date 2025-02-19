# Copyright(c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT license.

library(sqlmlutils)
library(testthat)

context("Tests for sqlmlutils package management dependencies")

test_that("single package install and removal with no dependencies",
{
    # There is an issue running this test in github actions CI environment.
    # We will need to investigate why it failed. For now, we will disable the test in CI.
    skip_on_ci()

    #
    # Set scope to public for trusted connection on Windows
    #
    scope <- if(!helper_isServerLinux()) "public" else "private"

    connectionStringDBO <- helper_getSetting("connectionStringDBO")
    packageName <- c("glue")
    
    tryCatch({
        #
        # check package management is installed
        #
        cat("checking remote lib paths...\n")
        helper_checkSqlLibPaths(connectionStringDBO, 1)

        #
        # remove old packages if any and verify they aren't there
        #
        if (helper_remote.require(connectionStringDBO, packageName) == TRUE)
        {
            cat("\nINFO: removing package...\n")
            sql_remove.packages(connectionStringDBO, packageName, verbose = TRUE, scope = scope)
        }

        helper_checkPackageStatusRequire( connectionStringDBO, packageName, FALSE)

        #
        # install single package (package has no dependencies)
        #
        output <- try(capture.output(sql_install.packages( connectionStringDBO, packageName, verbose = TRUE, scope = scope)))
        print(output)
        expect_true(!inherits(output, "try-error"))
        expect_equal(1, sum(grepl("Successfully installed packages on SQL server", output)))

        helper_checkPackageStatusRequire( connectionStringDBO, packageName, TRUE)
        helper_checkSqlLibPaths(connectionStringDBO, 2)

        #
        # remove the installed package and check again they are gone
        #
        cat("\nINFO:removing package...\n")
        output <- try(capture.output(sql_remove.packages( connectionStringDBO, packageName, verbose = TRUE, scope = scope)))
        print(output)
        expect_true(!inherits(output, "try-error"))
        expect_equal(1, sum(grepl("Successfully removed packages from SQL server", output)))

        helper_checkPackageStatusRequire( connectionStringDBO, packageName, FALSE)
    }, finally={
        helper_cleanAllExternalLibraries(connectionStringDBO)
    })
})

test_that( "package install and uninstall with dependency",
{
    # There is an issue running this test in github actions CI environment.
    # We will need to investigate why it failed. For now, we will disable the test in CI.
    skip_on_ci()

    connectionStringAirlineUserdbowner <- helper_getSetting("connectionStringAirlineUserdbowner")
    scope <- "private"
    
    tryCatch({
        #
        # check package management is installed
        #
        cat("\nINFO: checking remote lib paths...\n")
        helper_checkSqlLibPaths(connectionStringAirlineUserdbowner, 1)
    
        packageName <- c("A3")
        dependentPackageName <- "xtable"
    
        #
        # remove old packages if any and verify they aren't there
        #
        if (helper_remote.require(connectionStringAirlineUserdbowner, packageName) == TRUE)
        {
            cat("\nINFO: removing package:", packageName,"\n")
            sql_remove.packages( connectionStringAirlineUserdbowner, c(packageName), verbose = TRUE, scope = scope)
        }
    
        if (helper_remote.require(connectionStringAirlineUserdbowner, dependentPackageName) == TRUE)
        {
            cat("\nINFO: removing package:", dependentPackageName,"\n")
            sql_remove.packages( connectionStringAirlineUserdbowner, c(dependentPackageName), verbose = TRUE, scope = scope)
        }
    
        helper_checkPackageStatusRequire( connectionStringAirlineUserdbowner, packageName, FALSE)
        helper_checkPackageStatusRequire( connectionStringAirlineUserdbowner, dependentPackageName, FALSE)
    
        #
        # install the package with its dependencies and check if its present
        #
        output <- try(capture.output(sql_install.packages( connectionStringAirlineUserdbowner, packageName, verbose = TRUE, scope = scope)))
        print(output)
        expect_true(!inherits(output, "try-error"))
        expect_equal(1, sum(grepl("Successfully installed packages on SQL server", output)))
    
        helper_checkPackageStatusRequire( connectionStringAirlineUserdbowner,  packageName, TRUE)
        helper_checkPackageStatusRequire( connectionStringAirlineUserdbowner,  dependentPackageName, TRUE)
        helper_checkSqlLibPaths(connectionStringAirlineUserdbowner, 2)
    
        #
        # remove the installed packages and check again they are gone
        #
        cat("\nINFO: removing packages...\n")
        output <- try(capture.output(sql_remove.packages( connectionStringAirlineUserdbowner, packageName, verbose = TRUE, scope = scope)))
        print(output)
        expect_true(!inherits(output, "try-error"))
        expect_equal(1, sum(grepl("Successfully removed packages from SQL server", output)))
    
        helper_checkPackageStatusRequire( connectionStringAirlineUserdbowner, packageName, FALSE)
        helper_checkPackageStatusRequire( connectionStringAirlineUserdbowner, dependentPackageName, FALSE)
    }, finally={
        helper_cleanAllExternalLibraries(connectionStringAirlineUserdbowner)
    })
})

test_that( "Installing a package that is already in use",
{
    connectionStringAirlineUserdbowner <- helper_getSetting("connectionStringAirlineUserdbowner")
    scope <- "private"

    tryCatch({
        #
        # check package management is installed
        #
        cat("\nINFO: checking remote lib paths...\n")
        helper_checkSqlLibPaths(connectionStringAirlineUserdbowner, 1)
    
    
        packageName <- c("lattice") # usually already attached in an R session.
    
        installedPackages <- sql_installed.packages(connectionStringAirlineUserdbowner, fields = NULL, scope = scope)
        if (!packageName %in% installedPackages)
        {
            sql_install.packages(connectionStringAirlineUserdbowner, packageName, verbose = TRUE, scope = scope)
        }
    
        #
        # install the package again and check if it fails with the correct message.
        #
        output <- capture.output(sql_install.packages( connectionStringAirlineUserdbowner, packageName, verbose = TRUE, scope = scope))
        expect_true(TRUE %in% (grepl("already installed", output)))
    }, finally={
        helper_cleanAllExternalLibraries(connectionStringAirlineUserdbowner)
    })
})
