module Admin
  class StaticPagesController < BaseController
    before_action :require_admin!
    before_action :set_page, only: [:edit, :update, :destroy]

    def index
      @pages = StaticPage.order(:title)
    end

    def new
      @page = StaticPage.new
    end

    def create
      @page = StaticPage.new(page_params)
      if @page.save
        redirect_to admin_static_pages_path, notice: "Page created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @page.update(page_params)
        redirect_to admin_static_pages_path, notice: "Page updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @page.destroy
      redirect_to admin_static_pages_path, notice: "Page deleted."
    end

    private

    def set_page
      @page = StaticPage.find(params[:id])
    end

    def page_params
      params.require(:static_page).permit(:title, :slug, :body, :seo_title, :meta_description)
    end
  end
end
