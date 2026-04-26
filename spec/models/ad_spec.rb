require 'rails_helper'

RSpec.describe Ad, type: :model do
  describe "validations" do
    it "requires a name" do
      ad = build(:ad, name: nil)
      expect(ad).not_to be_valid
      expect(ad.errors[:name]).to be_present
    end

    it "requires a known ad_type" do
      ad = build(:ad, ad_type: "banner")
      expect(ad).not_to be_valid
      expect(ad.errors[:ad_type]).to be_present
    end

    it "requires a known placement_zone" do
      ad = build(:ad, placement_zone: "skyscraper")
      expect(ad).not_to be_valid
      expect(ad.errors[:placement_zone]).to be_present
    end

    it "requires link_url for direct ads" do
      ad = build(:ad, ad_type: "direct", link_url: nil)
      expect(ad).not_to be_valid
      expect(ad.errors[:link_url]).to be_present
    end

    it "requires script_code for adsense and custom_html ads" do
      adsense = build(:ad, ad_type: "adsense", script_code: nil, link_url: nil)
      expect(adsense).not_to be_valid
      expect(adsense.errors[:script_code]).to be_present

      custom = build(:ad, :script, script_code: nil)
      expect(custom).not_to be_valid
      expect(custom.errors[:script_code]).to be_present
    end

    it "rejects link_url that doesn't start with http(s)" do
      ad = build(:ad, link_url: "javascript:alert(1)")
      expect(ad).not_to be_valid
      expect(ad.errors[:link_url]).to be_present
    end

    it "rejects ends_at that is not after starts_at" do
      ad = build(:ad,
        starts_at: Time.zone.local(2026, 5, 1),
        ends_at:   Time.zone.local(2026, 5, 1))
      expect(ad).not_to be_valid
      expect(ad.errors[:ends_at]).to be_present
    end
  end

  describe "scopes" do
    let!(:active)         { create(:ad, status: "active") }
    let!(:paused)         { create(:ad, status: "paused") }
    let!(:archived)       { create(:ad, status: "archived") }

    it "active_status returns only active ads" do
      expect(Ad.active_status).to contain_exactly(active)
    end

    it "for_zone filters by placement_zone" do
      hero = create(:ad, placement_zone: "header_banner")
      expect(Ad.for_zone("header_banner")).to contain_exactly(hero)
    end

    describe ".currently_running" do
      it "includes ads with no start/end dates" do
        expect(Ad.currently_running).to include(active)
      end

      it "excludes ads not yet started" do
        future = create(:ad, status: "active", starts_at: 2.days.from_now)
        expect(Ad.currently_running).not_to include(future)
      end

      it "excludes ads already ended" do
        past = create(:ad, status: "active", ends_at: 2.days.ago)
        expect(Ad.currently_running).not_to include(past)
      end

      it "excludes paused ads even if dates are open" do
        expect(Ad.currently_running).not_to include(paused)
      end
    end
  end

  describe ".pick_for_zone" do
    it "returns the highest-priority running ad in the zone" do
      low  = create(:ad, placement_zone: "homepage_mid", priority: 1)
      high = create(:ad, placement_zone: "homepage_mid", priority: 10)
      _other_zone = create(:ad, placement_zone: "footer_banner", priority: 100)

      expect(Ad.pick_for_zone("homepage_mid")).to eq(high)
    end

    it "returns nil when no ad runs in the zone" do
      create(:ad, placement_zone: "homepage_mid", status: "paused")
      expect(Ad.pick_for_zone("homepage_mid")).to be_nil
    end
  end

  describe "#running?" do
    it "is true for an active ad with open dates" do
      expect(create(:ad, status: "active")).to be_running
    end

    it "is false for a paused ad" do
      expect(create(:ad, status: "paused")).not_to be_running
    end

    it "is false before starts_at" do
      expect(create(:ad, status: "active", starts_at: 1.day.from_now)).not_to be_running
    end

    it "is false after ends_at" do
      expect(create(:ad, status: "active", ends_at: 1.day.ago)).not_to be_running
    end
  end

  describe "#zone_label" do
    it "returns the human label for a known zone" do
      expect(build(:ad, placement_zone: "header_banner").zone_label).to eq("Header Banner (below nav)")
    end

    it "falls back to the zone key for an unknown zone" do
      ad = build(:ad)
      ad.placement_zone = "mystery"
      expect(ad.zone_label).to eq("mystery")
    end
  end
end
