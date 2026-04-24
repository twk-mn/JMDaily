require 'rails_helper'

RSpec.describe Setting, type: :model do
  describe 'validations' do
    it 'requires a key' do
      s = Setting.new(value_type: "string")
      expect(s).not_to be_valid
      expect(s.errors[:key]).to be_present
    end

    it 'enforces unique keys' do
      Setting.create!(key: "foo", value: "a", value_type: "string")
      dup = Setting.new(key: "foo", value: "b", value_type: "string")
      expect(dup).not_to be_valid
    end

    it 'rejects unknown value types' do
      s = Setting.new(key: "foo", value_type: "bogus")
      expect(s).not_to be_valid
      expect(s.errors[:value_type]).to be_present
    end
  end

  describe '.get / .set' do
    it 'returns the default when no row exists' do
      expect(Setting.get("site_name")).to eq("Joetsu-Myoko Daily")
    end

    it 'persists and reads back a value' do
      Setting.set("site_name", "New Site")
      expect(Setting.get("site_name")).to eq("New Site")
    end

    it 'coerces integers' do
      Setting.create!(key: "limit", value: "42", value_type: "integer")
      expect(Setting.get("limit")).to eq(42)
    end

    it 'coerces booleans' do
      Setting.create!(key: "enabled", value: "true", value_type: "boolean")
      expect(Setting.get("enabled")).to be true
    end

    it 'parses JSON' do
      Setting.create!(key: "nested", value: { "a" => 1 }.to_json, value_type: "json")
      expect(Setting.get("nested")).to eq({ "a" => 1 })
    end
  end

  describe '.bulk_update' do
    it 'persists all supplied keys' do
      Setting.bulk_update("site_name" => "Bulk", "tagline" => "hi")
      expect(Setting.get("site_name")).to eq("Bulk")
      expect(Setting.get("tagline")).to eq("hi")
    end
  end

  describe 'caching' do
    it 'reflects updates across reads' do
      Setting.set("site_name", "A")
      expect(Setting.get("site_name")).to eq("A")
      Setting.set("site_name", "B")
      expect(Setting.get("site_name")).to eq("B")
    end
  end

  describe '.definitions_for_tab' do
    it 'returns only definitions for the matching tab' do
      result = Setting.definitions_for_tab("general")
      expect(result.keys).to include("site_name", "tagline", "admin_email", "timezone")
    end
  end
end
