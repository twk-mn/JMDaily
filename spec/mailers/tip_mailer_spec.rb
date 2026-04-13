require "rails_helper"

RSpec.describe TipMailer do
  describe "#new_tip" do
    let(:tip) { create(:tip_submission, tip_body: "Suspicious activity near the station.") }
    let(:mail) { described_class.new_tip(tip) }

    it "is sent to the editor address" do
      expect(mail.to).to eq([ ENV.fetch("EDITOR_EMAIL", "editor@jmdaily.com") ])
    end

    it "has the correct subject" do
      expect(mail.subject).to eq("[JMDaily] New tip received")
    end

    it "renders the tip body in the HTML part" do
      expect(mail.html_part.body.decoded).to include("Suspicious activity near the station.")
    end

    it "renders the tip body in the text part" do
      expect(mail.text_part.body.decoded).to include("Suspicious activity near the station.")
    end
  end
end
