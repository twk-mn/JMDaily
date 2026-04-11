require 'rails_helper'

RSpec.describe AuditLog, type: :model do
  describe '.record' do
    let(:user)     { create(:user) }
    let(:article)  { create(:article) }

    it 'creates an audit log entry' do
      expect {
        AuditLog.record(user: user, action: "update", resource: article, ip: "127.0.0.1")
      }.to change(AuditLog, :count).by(1)
    end

    it 'captures resource type, id, and label' do
      AuditLog.record(user: user, action: "create", resource: article, ip: "1.2.3.4")
      log = AuditLog.last
      expect(log.resource_type).to eq("Article")
      expect(log.resource_id).to eq(article.id)
      expect(log.resource_label).to eq(article.title)
    end

    it 'captures ip address' do
      AuditLog.record(user: user, action: "destroy", resource: article, ip: "10.0.0.1")
      expect(AuditLog.last.ip_address).to eq("10.0.0.1")
    end

    it 'does not raise if resource label cannot be determined' do
      resource = double("Resource", class: double(name: "Unknown"), id: 99)
      allow(resource).to receive(:try).and_return(nil)
      expect {
        AuditLog.record(user: user, action: "update", resource: resource, ip: "127.0.0.1")
      }.not_to raise_error
    end

    it 'does not raise or propagate errors' do
      allow(AuditLog).to receive(:create!).and_raise(StandardError, "db error")
      expect {
        AuditLog.record(user: user, action: "update", resource: article, ip: "127.0.0.1")
      }.not_to raise_error
    end
  end

  describe 'scopes' do
    describe '.recent' do
      it 'orders by created_at desc' do
        older = create(:audit_log, created_at: 2.days.ago)
        newer = create(:audit_log, created_at: 1.hour.ago)
        expect(AuditLog.recent.first).to eq(newer)
      end
    end
  end
end
