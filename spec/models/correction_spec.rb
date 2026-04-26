require 'rails_helper'

RSpec.describe Correction, type: :model do
  describe "validations" do
    it "requires a body" do
      correction = build(:correction, body: nil)
      expect(correction).not_to be_valid
      expect(correction.errors[:body]).to be_present
    end

    it "defaults posted_at to the current time on create" do
      correction = create(:correction, posted_at: nil)
      expect(correction.posted_at).to be_within(1.second).of(Time.current)
    end

    it "requires an article" do
      correction = Correction.new(body: "x")
      expect(correction).not_to be_valid
      expect(correction.errors[:article]).to be_present
    end
  end

  describe "ordering" do
    it "is returned oldest-first by default" do
      article = create(:article, :published)
      newer = create(:correction, article: article, posted_at: 1.hour.ago)
      older = create(:correction, article: article, posted_at: 3.hours.ago)
      expect(article.corrections.to_a).to eq([ older, newer ])
    end
  end

  describe "deletion" do
    it "is destroyed when its article is destroyed" do
      article = create(:article)
      create(:correction, article: article)
      expect { article.destroy }.to change(Correction, :count).by(-1)
    end
  end
end
