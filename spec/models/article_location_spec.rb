require 'rails_helper'

RSpec.describe ArticleLocation, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:article) }
    it { is_expected.to belong_to(:location) }
  end
end
