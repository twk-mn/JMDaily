require 'rails_helper'

RSpec.describe SiteLanguage, type: :model do
  describe 'validations' do
    it 'requires a valid ISO code' do
      lang = SiteLanguage.new(code: "xx", position: 10)
      expect(lang).not_to be_valid
      expect(lang.errors[:code]).to be_present
    end

    it 'enforces uniqueness of code' do
      dup = SiteLanguage.new(code: "en", position: 99)
      expect(dup).not_to be_valid
    end
  end

  describe 'defaults from ISO options on create' do
    it 'backfills name/native_name/flag from ISO_OPTIONS' do
      lang = SiteLanguage.create!(code: "ko", position: 5, active: true, deletable: true)
      expect(lang.name).to eq("Korean")
      expect(lang.native_name).to eq("한국어")
      expect(lang.flag_emoji).to eq("🇰🇷")
    end
  end

  describe 'class-level caches' do
    it 'lists all codes' do
      expect(SiteLanguage.codes).to include("en", "ja")
    end

    it 'lists only active codes in active_codes' do
      ja = SiteLanguage.find_by(code: "ja")
      ja.update!(active: false)
      expect(SiteLanguage.active_codes).to include("en")
      expect(SiteLanguage.active_codes).not_to include("ja")
    end

    it 'lists required codes' do
      expect(SiteLanguage.required_codes).to include("en")
      expect(SiteLanguage.required_codes).not_to include("ja")
    end

    it 'invalidates cache on write' do
      SiteLanguage.codes # prime
      SiteLanguage.create!(code: "ko", position: 9, active: true, deletable: true)
      expect(SiteLanguage.codes).to include("ko")
    end
  end

  describe '#deactivatable?' do
    it 'returns false for the required language' do
      en = SiteLanguage.find_by(code: "en")
      expect(en.deactivatable?).to be false
    end

    it 'returns true for an optional active language with siblings' do
      ja = SiteLanguage.find_by(code: "ja")
      expect(ja.deactivatable?).to be true
    end

    it 'returns false if deactivating would leave zero active languages' do
      # Force JA inactive, so only EN remains active. EN cannot be deactivated
      # anyway (required), so deactivatable? must still be false for EN.
      SiteLanguage.find_by(code: "ja").update!(active: false)
      en = SiteLanguage.find_by(code: "en")
      expect(en.deactivatable?).to be false
    end
  end

  describe '#purgeable?' do
    it 'is false when active' do
      expect(SiteLanguage.find_by(code: "ja").purgeable?).to be false
    end

    it 'is false for required language' do
      en = SiteLanguage.find_by(code: "en")
      expect(en.purgeable?).to be false
    end

    it 'is true when deactivated and deletable' do
      ja = SiteLanguage.find_by(code: "ja")
      ja.update!(active: false)
      expect(ja.purgeable?).to be true
    end
  end

  describe '.addable_iso_options' do
    it 'excludes codes already present' do
      codes = SiteLanguage.addable_iso_options.map { |o| o[:code] }
      expect(codes).not_to include("en", "ja")
      expect(codes).to include("ko")
    end
  end

  describe '#content_counts' do
    it 'counts translations and newsletters per locale' do
      create(:article) # auto-creates EN translation
      counts = SiteLanguage.find_by(code: "en").content_counts
      expect(counts[:articles]).to eq(1)
    end
  end
end
