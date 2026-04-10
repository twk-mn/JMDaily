require 'rails_helper'

RSpec.describe Location, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:article_locations).dependent(:destroy) }
    it { is_expected.to have_many(:articles).through(:article_locations) }
  end

  describe 'validations' do
    subject { build(:location) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_uniqueness_of(:slug) }

    it 'requires slug (or name to auto-generate)' do
      location = build(:location, name: nil, slug: nil)
      expect(location).not_to be_valid
      expect(location.errors[:slug]).to be_present
    end
  end

  describe 'slug generation' do
    it 'auto-generates slug from name' do
      location = create(:location, name: "Joetsu City", slug: nil)
      expect(location.slug).to eq("joetsu-city")
    end
  end

  describe '#to_param' do
    it 'returns slug' do
      location = build(:location, slug: "joetsu")
      expect(location.to_param).to eq("joetsu")
    end
  end
end
