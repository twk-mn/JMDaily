class TagTranslation < ApplicationRecord
  belongs_to :tag

  validates :locale, presence: true,
                     inclusion: { in: ->(_) { SiteLanguage.codes } },
                     uniqueness: { scope: :tag_id, message: "translation already exists for this tag" }
end
