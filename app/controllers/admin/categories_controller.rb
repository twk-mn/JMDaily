module Admin
  class CategoriesController < BaseController
    before_action :require_admin!
    before_action :set_category, only: [ :edit, :update, :destroy ]

    def index
      @pagy, @categories = pagy(:offset, Category.order(:position, :name), limit: 50)
    end

    def new
      @category = Category.new
      build_translation_inputs
    end

    def create
      @category = Category.new(category_params)
      if @category.save
        redirect_to admin_categories_path, notice: "Category created."
      else
        build_translation_inputs
        render :new, status: :unprocessable_content
      end
    end

    def edit
      build_translation_inputs
    end

    def update
      if @category.update(category_params)
        redirect_to admin_categories_path, notice: "Category updated."
      else
        build_translation_inputs
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @category.destroy
        redirect_to admin_categories_path, notice: "Category deleted."
      else
        redirect_to admin_categories_path, alert: "Cannot delete a category with articles."
      end
    end

    private

    def set_category
      @category = find_resource(Category)
    end

    def category_params
      params.require(:category).permit(
        :name, :slug, :description, :position,
        translations_attributes: [ :id, :locale, :name, :description, :_destroy ]
      )
    end

    # Pre-build a translation row for every active non-English locale so the
    # form can render an input section per language. Mirrors the Location
    # admin flow.
    def build_translation_inputs
      (SiteLanguage.active_codes - [ "en" ]).each do |locale|
        @category.translations.find_or_initialize_by(locale: locale)
      end
    end
  end
end
