class CategoryTranslation < ApplicationRecord
  belongs_to :category

  validates :locale, presence: true,
                     inclusion: { in: ->(_) { SiteLanguage.codes } },
                     uniqueness: { scope: :category_id, message: "translation already exists for this category" }
end
