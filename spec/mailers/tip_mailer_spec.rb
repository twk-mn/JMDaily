require "rails_helper"

RSpec.describe TipMailer do
  describe "#new_tip" do
    let(:tip) { create(:tip_submission, tip_body: "Suspicious activity near the station.") }
    let(:mail) { described_class.new_tip(tip) }

    it "is sent to the configured admin email" do
      expect(mail.to).to eq([ Setting.admin_email ])
    end

    it "has the correct subject including the site name" do
      expect(mail.subject).to eq("[#{Setting.site_name}] New tip received")
    end

    it "honors a custom admin_email setting" do
      Setting.set("admin_email", "tips@example.com")
      expect(described_class.new_tip(tip).to).to eq([ "tips@example.com" ])
    end

    it "honors a custom site_name setting in the subject" do
      Setting.set("site_name", "My News Site")
      expect(described_class.new_tip(tip).subject).to eq("[My News Site] New tip received")
    end

    it "renders the tip body in the HTML part" do
      expect(mail.html_part.body.decoded).to include("Suspicious activity near the station.")
    end

    it "renders the tip body in the text part" do
      expect(mail.text_part.body.decoded).to include("Suspicious activity near the station.")
    end
  end
end
