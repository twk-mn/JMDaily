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

    # Regression: Setting.get used to wrap reads in Rails.cache with a
    # version-based key. The default Rails.cache store is per-process, so a
    # write in one Puma worker left other workers serving stale values until
    # the TTL expired. We model that by writing directly to the underlying
    # row and confirming the next read sees it without any cache nudge.
    it 'reflects out-of-band row updates immediately' do
      Setting.set("site_name", "first")
      expect(Setting.get("site_name")).to eq("first")

      Setting.find_by!(key: "site_name").update_columns(value: "second")
      expect(Setting.get("site_name")).to eq("second")
    end
  end

  describe 'convenience accessors' do
    describe '.site_name' do
      it 'returns the registered default when no row exists' do
        expect(Setting.site_name).to eq("Joetsu-Myoko Daily")
      end

      it 'returns the saved value when present' do
        Setting.set("site_name", "Niigata News")
        expect(Setting.site_name).to eq("Niigata News")
      end

      it 'falls back to the default when the saved value is blank' do
        Setting.set("site_name", "")
        expect(Setting.site_name).to eq("Joetsu-Myoko Daily")
      end
    end

    describe '.site_tagline' do
      it 'returns an empty string when unset' do
        expect(Setting.site_tagline).to eq("")
      end

      it 'returns the saved tagline' do
        Setting.set("tagline", "Local news in English")
        expect(Setting.site_tagline).to eq("Local news in English")
      end
    end

    describe '.admin_email' do
      it 'falls back to ENV[EDITOR_EMAIL] when no setting saved' do
        expected = ENV.fetch("EDITOR_EMAIL", "editor@jmdaily.com")
        expect(Setting.admin_email).to eq(expected)
      end

      it 'returns the saved admin_email when present' do
        Setting.set("admin_email", "editor@example.com")
        expect(Setting.admin_email).to eq("editor@example.com")
      end

      it 'falls back to ENV when the saved value is blank' do
        Setting.set("admin_email", "")
        expected = ENV.fetch("EDITOR_EMAIL", "editor@jmdaily.com")
        expect(Setting.admin_email).to eq(expected)
      end
    end
  end

  describe '.definitions_for_tab' do
    it 'returns only definitions for the matching tab' do
      result = Setting.definitions_for_tab("general")
      expect(result.keys).to include("site_name", "tagline", "admin_email", "timezone")
    end
  end
end
