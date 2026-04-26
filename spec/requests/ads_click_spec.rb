require 'rails_helper'

RSpec.describe "Ads click tracking", type: :request do
  describe "GET /ads/:id/click" do
    it "redirects to the ad's link_url for a direct ad" do
      ad = create(:ad, ad_type: "direct", link_url: "https://sponsor.example.com/landing")

      get ad_click_path(ad)

      expect(response).to redirect_to("https://sponsor.example.com/landing")
    end

    it "enqueues a RecordAdClickJob with the ad id" do
      ad = create(:ad, ad_type: "direct", link_url: "https://sponsor.example.com/landing")

      expect {
        get ad_click_path(ad)
      }.to have_enqueued_job(RecordAdClickJob).with(ad.id)
    end

    it "does not redirect to an unsafe link_url scheme" do
      ad = create(:ad, ad_type: "direct", link_url: "https://ok.example.com/x")
      # Simulate a tampered DB row by stubbing the URL after persistence so the
      # click endpoint's safety check is exercised in isolation from validations.
      allow(Ad).to receive(:find).with(ad.id.to_s).and_return(ad)
      allow(ad).to receive(:link_url).and_return("javascript:alert(1)")

      get ad_click_path(ad)

      expect(response).to redirect_to(root_path)
    end

    it "redirects to root for non-direct ads (no tracked link)" do
      ad = create(:ad, :script)

      get ad_click_path(ad)

      expect(response).to redirect_to(root_path)
    end

    it "404s for an unknown ad id" do
      get "/ads/999999/click"
      expect(response).to have_http_status(:not_found)
    end
  end
end
