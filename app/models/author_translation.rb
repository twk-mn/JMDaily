class AuthorTranslation < ApplicationRecord
  belongs_to :author

  validates :locale, presence: true,
                     inclusion: { in: ->(_) { SiteLanguage.codes } },
                     uniqueness: { scope: :author_id, message: "translation already exists for this author" }
end
