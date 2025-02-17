#' Internal: empty_plot
#'
#' This function is called within the metadata_map function. \cr \cr
#' It plots  \cr \cr
#' @param dataframe Dataframe to plot. Output of empty_count.R function.
#' @param bar_title Title for the plot.
#' @return A plotly object
#' @importFrom plotly plot_ly layout
#' @keywords internal
#' @dev generate help files for unexported objects, for developers

empty_plot <- function(dataframe, bar_title) {
  barplot_html <- plot_ly(dataframe,
    x = ~Table,
    y = ~N_Variables,
    color = ~Empty,
    colors = c("grey", "darkturquoise"),
    type = "bar",
    text = ~N_Variables,
    textposition = "inside",
    texttemplate = "%{text}",
    textfont = list(color = "black", size = 10)
  ) %>%
    layout(
      barmode = "stack",
      title = bar_title,
      xaxis = list(title = "Table"),
      yaxis = list(title = "Variable Count"),
      legend = list(title = list(text = "Empty Description"))
    )

  barplot_html
}

#' Internal: end_plot
#'
#' This function is called within the metadata_map function. \cr \cr
#' A summary plot is created that includes the domain code reference table and
#' counts of domain code categorisations \cr \cr
#'
#' @param df The Output dataframe with all the domain categorisations
#' @param table_name Table name
#' @param ref_table Domain code reference table (domains mapped to integers)
#' @return It returns a ggplot
#' @keywords internal
#' @importFrom dplyr %>% group_by count arrange
#' @importFrom stats reorder
#' @importFrom gridExtra grid.arrange
#' @import ggplot2

end_plot <- function(df, table_name, ref_table) {
  counts <- df %>%
    group_by(domain_code) %>%
    count() %>%
    arrange(n)

  domain_plot <- counts %>%
    ggplot(aes(x = reorder(domain_code, -n), y = n)) +
    geom_col() +
    ggtitle(paste("Variables in", table_name, "grouped by domain code")) +
    theme_gray(base_size = 18) +
    theme(axis.text.x = element_text(
      angle = 90,
      vjust = 0.5,
      hjust = 1
    )) +
    xlab("Domain Code") +
    ylab("Count") +
    scale_y_continuous(breaks = seq(0, max(counts$n), 1))

  full_plot <- grid.arrange(domain_plot,
    ref_table,
    nrow = 1,
    ncol = 2
  )
  return(full_plot)
}
