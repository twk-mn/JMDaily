require "rails_helper"

RSpec.describe ContactMailer do
  describe "#new_submission" do
    let(:submission) { create(:contact_submission, name: "Jane Doe", email: "jane@example.com", subject: "Hello there", message: "Great site!") }
    let(:mail) { described_class.new_submission(submission) }

    it "is sent to the editor address" do
      expect(mail.to).to eq([ENV.fetch("EDITOR_EMAIL", "editor@jmdaily.com")])
    end

    it "sets reply-to to the submitter" do
      expect(mail.reply_to).to eq(["jane@example.com"])
      expect(mail["reply-to"].value).to include("Jane Doe")
    end

    it "includes the submitter name in the subject" do
      expect(mail.subject).to include("Hello there")
    end

    it "renders the submitter name in the HTML body" do
      expect(mail.html_part.body.decoded).to include("Jane Doe")
    end

    it "renders the message body in the HTML part" do
      expect(mail.html_part.body.decoded).to include("Great site!")
    end

    it "renders the message body in the text part" do
      expect(mail.text_part.body.decoded).to include("Great site!")
    end

    context "when subject is blank" do
      let(:submission) { create(:contact_submission, subject: "") }

      it "uses a fallback subject" do
        expect(mail.subject).to include("(no subject)")
      end
    end
  end
end
