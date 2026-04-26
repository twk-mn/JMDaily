require 'rails_helper'

RSpec.describe RecordAdClickJob, type: :job do
  it "increments the ad's clicks_count by one" do
    ad = create(:ad, clicks_count: 4)
    expect { described_class.perform_now(ad.id) }.to change { ad.reload.clicks_count }.from(4).to(5)
  end

  it "is a no-op when the ad no longer exists" do
    expect { described_class.perform_now(999_999) }.not_to raise_error
  end

  it "uses an atomic update (no read-modify-write race)" do
    ad = create(:ad, clicks_count: 0)
    # Two parallel jobs in the same process — both should land.
    described_class.perform_now(ad.id)
    described_class.perform_now(ad.id)
    expect(ad.reload.clicks_count).to eq(2)
  end
end
