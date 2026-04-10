class ArticleLocation < ApplicationRecord
  belongs_to :article
  belongs_to :location
end
