#' @title Remove data still under QA/QC.
#'
#' @description
#' Removes records that are still undergoing QA/QC (latest 12 months)
#'
#' @param full_data Data.table of raw data.
#' @param trapping_table Data.table with QCflag
#'
#' @return Data.table with latest 12 months of data removed.
#'
#' @noRd
clean_data <- function(full_data, trapping_table, ...) {
  columns_to_keep <- colnames(full_data)
  full_data <- full_data %>%
    dplyr::left_join(trapping_table, ...) %>%
    dplyr::filter(.data$qcflag == 1) %>%
    dplyr::select(dplyr::all_of(columns_to_keep)) %>%
    unique()

  return(full_data)
}

#' @title Filter plots
#'
#' @description
#'   Removes plots not needed for analysis. Specific groups, such as "all" or
#'   "longterm" can be specified, as well as manual selection of plots.
#'
#' @param data any data.frame with a plot column.
#' @param plots specify subset of plots; can be a vector of plots, or specific
#'   sets: "all" plots or "longterm" plots (plots that have had the same
#'   treatment for the entire time series)
#' @return Data.table filtered to the desired subset of plots.
#'
#' @noRd
filter_plots <- function(data, plots = NULL)
{
  if (is.character(plots))
  {
    plots <- tolower(plots)
    if (plots %in% c("longterm", "long-term"))
    {
      plots <- c(3, 4, 10, 11, 14, 15, 16, 17, 19, 21, 23)
    } else if (plots == "all") {
      plots <- NULL
    }
  }

  # if no selection then return unaltered data
  return_if_null(x = plots, value = data)


  # otherwise return filtered data
  dplyr::filter(data, .data$plot %in% plots)
}

#' @title Join plots table
#' @description Adds treatment information to any data.frame with year, month,
#'   and plot info, by joining the plots_table
#' @param df data.frame to which plot and treatment info should be joined
#' @param plots_table Data_table of treatments for the plots.
#'
#' @return Data.table of raw rodent data with treatment info added.
#'
#' @noRd
join_plots <- function(df, plots_table) {
  plots_table <- plots_table %>%
    dplyr::group_by(.data$year, .data$plot) %>%
    dplyr::select(c("year", "month", "plot", "treatment"))

  join_by <- c(year = "year", month = "month", plot = "plot")
  dplyr::left_join(df, plots_table, by = join_by)
}


#' @title Add User-specified time column
#'
#' @description
#' period codes denote the number of censuses that have occurred, but are
#' not the same as the number of censuses that should have occurred. Sometimes
#' censuses are missed (weather, transport issues,etc). You can't pick this
#' up with the period code. Because censuses may not always occur monthly due to
#' the new moon -  a new moon code was devised to give a standardized language
#' of time for forecasting in particular. This function allows the user to decide
#' if they want to use the rodent period code, the new moon code, the date of
#' the rodent census, or have their data with all three time formats
#'
#' @param summary_table Data.table with summarized rodent data.
#' @param newmoon_table Data_table linking new moon codes with period codes.
#' @param time Character. Denotes whether new moon codes, period codes,
#' and/or date are desired.
#'
#' @return Data.table of summarized rodent data with user-specified time format
#'
#' @noRd
add_time <- function(summary_table, newmoons_table, time = "period") {
  newmoons_table$censusdate <- as.Date(newmoons_table$censusdate)
  newmoons_table$newmoondate <- as.Date(newmoons_table$newmoondate)
  if (time == "period")
  {
    join_summary_newmoon <- dplyr::right_join(newmoons_table, summary_table,
                                              by = c("period" = "period")) %>%
      dplyr::filter(.data$period <= max(.data$period, na.rm = TRUE))
  } else {
    newmoons_table$censusdate[is.na(newmoons_table$censusdate)] <-
      newmoons_table$newmoondate[is.na(newmoons_table$censusdate)]
    vars_to_complete <- names(dplyr::select(summary_table,tidyselect::any_of(c("species","plot"))))
    join_summary_newmoon <- dplyr::left_join(newmoons_table, summary_table,
                                             by = "period") %>%
                            tidyr::complete(tidyr::nesting(!!!rlang::syms(c("newmoonnumber",
                                                           "newmoondate",
                                                           "censusdate"))),
                                            !!!rlang::syms(vars_to_complete)) %>%
                            tidyr::drop_na(tidyselect::any_of(c("species","plot")))
  }
  date_vars <- c("newmoondate", "newmoonnumber", "period", "censusdate")
  vars_to_keep <- switch(tolower(time),
                         "newmoon" = "newmoonnumber",
                         "date" = "censusdate",
                         "period" = "period",
                         c("newmoonnumber", "period", "censusdate"))
  vars_to_drop <- setdiff(date_vars, vars_to_keep)
  dplyr::select(join_summary_newmoon, -tidyselect::any_of(vars_to_drop))
}

#' @title Make Crosstab
#'
#' @description convert summarized rodent data to crosstab form
#'
#' @param summary_data summarized rodent data
#' @param variable_name what variable to spread (default is "abundance")
#' @param ... other arguments to pass on to tidyr::spread
#'
#' @noRd
make_crosstab <- function(summary_data,
                          variable_name = "abundance",
                          ...)
{
  species <- as.character(na.omit(unique(summary_data$species)))
  vars_to_keep <- c(setdiff(names(summary_data), c("species", variable_name)),
                    sort(species))
  summary_data %>%
    tidyr::spread(.data$species, !!variable_name, ...) %>%
    dplyr::ungroup() %>%
    dplyr::select(tidyselect::all_of(vars_to_keep))
}
