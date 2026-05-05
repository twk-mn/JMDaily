module Admin
  class StaticPagesController < BaseController
    before_action :require_admin!
    before_action :set_page, only: [ :edit, :update, :destroy ]

    def index
      @pages = StaticPage.order(:title)
    end

    def new
      @page = StaticPage.new
      build_translation_inputs
    end

    def create
      @page = StaticPage.new(page_params)
      if @page.save
        redirect_to admin_static_pages_path, notice: "Page created."
      else
        build_translation_inputs
        render :new, status: :unprocessable_content
      end
    end

    def edit
      build_translation_inputs
    end

    def update
      if @page.update(page_params)
        redirect_to admin_static_pages_path, notice: "Page updated."
      else
        build_translation_inputs
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @page.destroy
      redirect_to admin_static_pages_path, notice: "Page deleted."
    end

    private

    def set_page
      @page = find_resource(StaticPage)
    end

    def page_params
      params.require(:static_page).permit(
        :title, :slug, :body, :seo_title, :meta_description,
        translations_attributes: [ :id, :locale, :title, :seo_title, :meta_description, :body, :_destroy ]
      )
    end

    def build_translation_inputs
      (SiteLanguage.active_codes - [ "en" ]).each do |locale|
        @page.translations.find_or_initialize_by(locale: locale)
      end
    end
  end
end
