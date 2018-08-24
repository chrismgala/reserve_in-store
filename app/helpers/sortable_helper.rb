module SortableHelper

  ##
  # @param [String] column - The specified column that we're sorting by
  # @param [String] title - The display text for the column header
  # @return [String] - HTML-safe link with a button class for sorting
  def sortable(column, title)
    direction = (column == @sort_column && @sort_direction == 'asc') ? 'desc' : 'asc'
    link_to({column: column, direction: direction}, {class: "Polaris-Button Polaris-Button--plain "}) do
      title.html_safe + sort_arrow(column)
    end
  end

  ##
  # @param [String] column - The specified column that we're sorting by
  # @return [String] - HTML to render an arrow pointing in the correct direction for the column
  def sort_arrow(column)
    if column == @sort_column && @sort_direction == "asc"
      render partial: 'layouts/partials/polaris_sort_arrows', locals: {svg_arrow_path: '<path d="M15 12l-5-5-5 5z"></path>'.html_safe}
    else
      render partial: 'layouts/partials/polaris_sort_arrows', locals: {svg_arrow_path: '<path d="M5 8l5 5 5-5z"></path>'.html_safe}
    end
  end
end
