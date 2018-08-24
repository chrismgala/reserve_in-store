module HasSortableColumns
  extend ActiveSupport::Concern

  ##
  # A string query to sort the provided column by the provided direction
  # @return [String] - A query fitting for @model.order()
  def column_sort_query
    "#{sort_column} #{sort_direction}"
  end

  private

  ##
  # Checks to ensure the column param is part of the whitelisted array
  # @return [String] - The column name (defaults to 'created_at')
  def sort_column
    @sort_column ||= sortable_columns.include?(params[:column]) ? params[:column] : 'created_at'
  end

  ##
  # Checks to ensure the direction param is either 'asc' or 'desc'
  # @return [String] - The direction for sorting (defaults to 'desc')
  def sort_direction
    @sort_direction ||=['asc', 'desc'].include?(params[:direction]) ? params[:direction] : 'desc'
  end
end
