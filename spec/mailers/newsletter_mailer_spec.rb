require "rails_helper"

RSpec.describe NewsletterMailer do
  describe "#confirmation" do
    let(:subscriber) { build(:newsletter_subscriber, confirmation_token: "tok123") }
    let(:mail) { described_class.confirmation(subscriber) }

    it "is sent to the subscriber" do
      expect(mail.to).to eq([ subscriber.email ])
    end

    it "has the correct subject" do
      expect(mail.subject).to eq("Confirm your subscription to Joetsu-Myoko Daily")
    end

    it "includes the confirmation URL in the HTML body" do
      expect(mail.html_part.body.decoded).to include("tok123")
    end

    it "includes the confirmation URL in the text body" do
      expect(mail.text_part.body.decoded).to include("tok123")
    end
  end

  describe "#broadcast" do
    let(:subscriber) { build(:newsletter_subscriber, :confirmed, unsubscribe_token: "unsub999") }

    context "with an English issue" do
      let(:issue) { build(:newsletter_issue, subject: "Today's news", body: "Hello world", locale: "en") }
      let(:mail) { described_class.broadcast(subscriber, issue) }

      it "is sent to the subscriber" do
        expect(mail.to).to eq([ subscriber.email ])
      end

      it "uses the issue subject" do
        expect(mail.subject).to eq("Today's news")
      end

      it "includes the issue body in the HTML part" do
        expect(mail.html_part.body.decoded).to include("Hello world")
      end

      it "includes the issue body in the text part" do
        expect(mail.text_part.body.decoded).to include("Hello world")
      end

      it "includes the unsubscribe token in the HTML part" do
        expect(mail.html_part.body.decoded).to include("unsub999")
      end

      it "links to the English home URL" do
        expect(mail.html_part.body.decoded).to include("/en/")
      end

      it "links to the English unsubscribe URL" do
        expect(mail.html_part.body.decoded).to include("/en/")
      end
    end

    context "with a Japanese issue" do
      let(:issue) { build(:newsletter_issue, subject: "今日のニュース", body: "こんにちは", locale: "ja") }
      let(:mail) { described_class.broadcast(subscriber, issue) }

      it "links to the Japanese home URL" do
        expect(mail.html_part.body.decoded).to include("/ja/")
      end

      it "links to the Japanese unsubscribe URL" do
        expect(mail.html_part.body.decoded).to include("/ja/")
      end
    end
  end
end
