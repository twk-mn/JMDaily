module Admin
  class TagsController < BaseController
    before_action :set_tag, only: [ :edit, :update, :destroy ]

    def index
      @tags = Tag.order(:name)
    end

    def new
      @tag = Tag.new
      build_translation_inputs
    end

    def create
      @tag = Tag.new(tag_params)
      if @tag.save
        redirect_to admin_tags_path, notice: "Tag created."
      else
        build_translation_inputs
        render :new, status: :unprocessable_content
      end
    end

    def edit
      build_translation_inputs
    end

    def update
      if @tag.update(tag_params)
        redirect_to admin_tags_path, notice: "Tag updated."
      else
        build_translation_inputs
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @tag.destroy
      redirect_to admin_tags_path, notice: "Tag deleted."
    end

    private

    def set_tag
      @tag = find_resource(Tag)
    end

    def tag_params
      params.require(:tag).permit(
        :name, :slug,
        translations_attributes: [ :id, :locale, :name, :_destroy ]
      )
    end

    def build_translation_inputs
      (SiteLanguage.active_codes - [ "en" ]).each do |locale|
        @tag.translations.find_or_initialize_by(locale: locale)
      end
    end
  end
end
