require 'rails_helper'

RSpec.describe NewsletterSubscriber, type: :model do
  describe 'validations' do
    subject { build(:newsletter_subscriber) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }

    it 'rejects invalid email format' do
      expect(build(:newsletter_subscriber, email: "not-an-email")).not_to be_valid
    end

    it 'accepts valid email' do
      expect(build(:newsletter_subscriber, email: "reader@example.com")).to be_valid
    end
  end

  describe 'before_create' do
    it 'generates a confirmation token' do
      subscriber = create(:newsletter_subscriber)
      expect(subscriber.confirmation_token).to be_present
    end

    it 'generates a unique token each time' do
      a = create(:newsletter_subscriber)
      b = create(:newsletter_subscriber)
      expect(a.confirmation_token).not_to eq(b.confirmation_token)
    end
  end

  describe '#confirmed?' do
    it 'returns false when not confirmed' do
      expect(build(:newsletter_subscriber, confirmed_at: nil)).not_to be_confirmed
    end

    it 'returns true when confirmed' do
      expect(build(:newsletter_subscriber, :confirmed)).to be_confirmed
    end
  end

  describe '#unsubscribed?' do
    it 'returns false when active' do
      expect(build(:newsletter_subscriber, :confirmed)).not_to be_unsubscribed
    end

    it 'returns true when unsubscribed' do
      expect(build(:newsletter_subscriber, :unsubscribed)).to be_unsubscribed
    end
  end

  describe '#confirm!' do
    it 'sets confirmed_at and clears token' do
      subscriber = create(:newsletter_subscriber)
      expect { subscriber.confirm! }
        .to change { subscriber.reload.confirmed_at }.from(nil)
        .and change { subscriber.confirmation_token }.to(nil)
    end

    context 'when an audience provider is configured' do
      before do
        Setting.set("newsletter_provider", "resend")
        Setting.set("newsletter_api_key", "re_abc")
        Setting.set("newsletter_audience_id", "aud_123")
      end

      it 'enqueues a SyncNewsletterAudienceJob with the subscribe action' do
        subscriber = create(:newsletter_subscriber)
        expect { subscriber.confirm! }
          .to have_enqueued_job(SyncNewsletterAudienceJob).with(subscriber.id, "subscribe")
      end
    end

    it 'does not enqueue an audience sync when no provider is configured' do
      subscriber = create(:newsletter_subscriber)
      expect { subscriber.confirm! }.not_to have_enqueued_job(SyncNewsletterAudienceJob)
    end
  end

  describe '#unsubscribe!' do
    it 'sets unsubscribed_at' do
      subscriber = create(:newsletter_subscriber, :confirmed)
      expect { subscriber.unsubscribe! }
        .to change { subscriber.reload.unsubscribed_at }.from(nil)
    end

    context 'when an audience provider is configured' do
      before do
        Setting.set("newsletter_provider", "resend")
        Setting.set("newsletter_api_key", "re_abc")
        Setting.set("newsletter_audience_id", "aud_123")
      end

      it 'enqueues a SyncNewsletterAudienceJob with the unsubscribe action' do
        subscriber = create(:newsletter_subscriber, :confirmed)
        expect { subscriber.unsubscribe! }
          .to have_enqueued_job(SyncNewsletterAudienceJob).with(subscriber.id, "unsubscribe")
      end
    end
  end

  describe 'scopes' do
    let!(:pending)      { create(:newsletter_subscriber) }
    let!(:confirmed)    { create(:newsletter_subscriber, :confirmed) }
    let!(:unsubscribed) { create(:newsletter_subscriber, :unsubscribed) }

    describe '.confirmed' do
      it 'returns confirmed subscribers' do
        expect(NewsletterSubscriber.confirmed).to include(confirmed, unsubscribed)
        expect(NewsletterSubscriber.confirmed).not_to include(pending)
      end
    end

    describe '.active' do
      it 'returns confirmed and not unsubscribed' do
        expect(NewsletterSubscriber.active).to include(confirmed)
        expect(NewsletterSubscriber.active).not_to include(pending, unsubscribed)
      end
    end
  end
end
