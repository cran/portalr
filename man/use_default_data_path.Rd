% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/download_data.R
\name{check_default_data_path}
\alias{check_default_data_path}
\alias{get_default_data_path}
\alias{use_default_data_path}
\title{Manage the default path for downloading Portal Data into}
\usage{
check_default_data_path(
  ENV_VAR = "PORTALR_DATA_PATH",
  MESSAGE_FUN = message,
  DATA_NAME = "Portal data"
)

get_default_data_path(fallback = "~", ENV_VAR = "PORTALR_DATA_PATH")

use_default_data_path(path = NULL, ENV_VAR = "PORTALR_DATA_PATH")
}
\arguments{
\item{ENV_VAR}{the environmental variable to check (by default
`"PORTALR_DATA_PATH"``)}

\item{MESSAGE_FUN}{the function to use to output messages}

\item{DATA_NAME}{the name of the dataset to use in output messages}

\item{fallback}{the default value to use if the setting is missing}

\item{path}{\code{character} Folder into which data will be downloaded.}
}
\value{
FALSE if there is no path set, TRUE otherwise

None
}
\description{
\code{check_default_data_path} checks if a default data path is
  set, and prompts the user to set it if it is missing.

\code{get_default_data_path} gets the value of the data path
  environmental variable

\code{use_default_data_path} has 3 steps. First, it checks for
  the presence of a pre-existing setting for the environmental variable.
  Then it checks if the folder exists and creates it, if needed. Then it
  provides instructions for setting the environmental variable.
}
