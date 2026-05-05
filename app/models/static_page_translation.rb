class StaticPageTranslation < ApplicationRecord
  belongs_to :static_page
  has_rich_text :body

  validates :locale, presence: true,
                     inclusion: { in: ->(_) { SiteLanguage.codes } },
                     uniqueness: { scope: :static_page_id, message: "translation already exists for this page" }
end
