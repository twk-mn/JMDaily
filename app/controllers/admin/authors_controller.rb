module Admin
  class AuthorsController < BaseController
    before_action :set_author, only: [ :edit, :update, :destroy ]

    def index
      @authors = Author.order(:name)
    end

    def new
      @author = Author.new
    end

    def create
      @author = Author.new(author_params)
      if @author.save
        redirect_to admin_authors_path, notice: "Author created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @author.update(author_params)
        redirect_to admin_authors_path, notice: "Author updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @author.destroy
        redirect_to admin_authors_path, notice: "Author deleted."
      else
        redirect_to admin_authors_path, alert: "Cannot delete an author with articles."
      end
    end

    private

    def set_author
      @author = Author.find(params[:id])
    end

    def author_params
      params.require(:author).permit(:name, :slug, :bio, :role_title, :twitter_url, :website_url, :photo, :user_id)
    end
  end
end
