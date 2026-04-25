class SearchController < ApplicationController
  include Pagy::Method

  def index
    @query = params[:q].to_s.strip
    @japanese = @query.present? && Article.japanese?(@query)
    @selected_category = Category.find_by(slug: params[:category]) if params[:category].present?

    if @query.present?
      base = Article.search(@query).includes(:category, :translations, :author)

      counts_by_id = base.unscope(:order).group(:category_id).count
      @total_count = counts_by_id.values.sum
      @category_counts = Category.where(id: counts_by_id.keys)
                                 .map { |c| [ c, counts_by_id[c.id] ] }
                                 .sort_by { |c, _| c.name }

      base = base.where(category: @selected_category) if @selected_category
      @pagy, @articles = pagy(:offset, base, limit: 12)
    else
      @articles = []
      @category_counts = []
      @total_count = 0
    end
  end
end
