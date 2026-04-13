require 'rails_helper'

RSpec.describe StaticPage, type: :model do
  describe 'validations' do
    subject { build(:static_page) }

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_uniqueness_of(:slug) }

    it 'requires slug (or title to auto-generate)' do
      page = build(:static_page, title: nil, slug: nil)
      expect(page).not_to be_valid
      expect(page.errors[:slug]).to be_present
    end
  end

  describe 'slug generation' do
    it 'auto-generates slug from title' do
      page = create(:static_page, title: "Privacy Policy", slug: nil)
      expect(page.slug).to eq("privacy-policy")
    end
  end

  describe '#to_param' do
    it 'returns slug' do
      page = build(:static_page, slug: "about")
      expect(page.to_param).to eq("about")
    end
  end
end
