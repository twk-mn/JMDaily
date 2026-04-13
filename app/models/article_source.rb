class ArticleSource < ApplicationRecord
  belongs_to :article

  validates :name, presence: true
  validates :url, format: { with: /\Ahttps?:\/\/.+\z/i, message: "must start with http:// or https://" },
                  allow_blank: true

  default_scope { order(:position, :id) }
end
