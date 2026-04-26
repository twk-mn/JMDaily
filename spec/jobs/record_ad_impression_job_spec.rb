require 'rails_helper'

RSpec.describe RecordAdImpressionJob, type: :job do
  it "increments the ad's impressions_count by one" do
    ad = create(:ad, impressions_count: 9)
    expect { described_class.perform_now(ad.id) }.to change { ad.reload.impressions_count }.from(9).to(10)
  end

  it "is a no-op when the ad no longer exists" do
    expect { described_class.perform_now(999_999) }.not_to raise_error
  end
end
