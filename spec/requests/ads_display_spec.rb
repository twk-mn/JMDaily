require 'rails_helper'

RSpec.describe "Ad rendering", type: :request do
  describe "the shared ad partial via the homepage_mid zone" do
    let!(:script_ad) do
      create(:ad, :script,
             placement_zone: "homepage_mid",
             sponsor_label: "Sponsored by Acme",
             script_code: %(<div class="custom-ad">Sponsor block</div>))
    end

    before { get locale_root_path }

    it "wraps the ad in a labeled landmark so screen readers can identify it" do
      expect(response.body).to include('<aside class="ad-unit')
      expect(response.body).to include('aria-label="Sponsored by Acme"')
    end

    it "always shows the disclosure label even when an image isn't attached" do
      expect(response.body).to match(/Sponsored by Acme/)
    end

    it "renders custom_html script code raw" do
      expect(response.body).to include('<div class="custom-ad">Sponsor block</div>')
    end
  end

  describe "direct ad without a sponsor label" do
    let!(:direct_ad) do
      create(:ad, placement_zone: "homepage_mid", sponsor_label: nil)
    end

    it "falls back to a generic 'Sponsored' disclosure" do
      get locale_root_path
      expect(response.body).to include('aria-label="Sponsored"')
    end
  end

  describe "no ad configured for the zone" do
    it "renders nothing for the zone" do
      get locale_root_path
      expect(response.body).not_to include('class="ad-unit')
    end
  end
end
