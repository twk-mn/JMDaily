class Setting < ApplicationRecord
  VALUE_TYPES = %w[string text integer boolean json].freeze

  # Centralised registry of the settings the site knows about. Adding a key here
  # gives it a default, a type, and a label — the admin UI iterates this to render
  # form fields, and Setting.get falls back to the default when no row exists.
  DEFINITIONS = {
    "site_name" => {
      type: "string", default: "Joetsu-Myoko Daily", tab: "general",
      label: "Site name",
      description: "Shown in the header and browser title."
    },
    "tagline" => {
      type: "string", default: "", tab: "general",
      label: "Tagline",
      description: "Short description shown alongside the site name."
    },
    "admin_email" => {
      type: "string", default: "", tab: "general",
      label: "Admin email",
      description: "Contact form submissions and system alerts are delivered here."
    },
    "timezone" => {
      type: "string", default: "Asia/Tokyo", tab: "general",
      label: "Timezone",
      description: "Default timezone for display of dates and times."
    }
  }.freeze

  validates :key, presence: true, uniqueness: true
  validates :value_type, inclusion: { in: VALUE_TYPES }

  after_commit :bust_cache

  class << self
    # Read a setting value, coerced to its declared type. Falls back to the
    # default in DEFINITIONS, then to nil. Cached per-key with version-based
    # invalidation so writes in one process are picked up by others at their
    # next read.
    def get(key)
      key = key.to_s
      Rails.cache.fetch(cache_key(key), expires_in: 1.hour) do
        row = find_by(key: key)
        row ? coerce(row.value, row.value_type) : default_for(key)
      end
    end

    # Upsert a value. Uses the declared type from DEFINITIONS if present,
    # otherwise preserves the existing row's type.
    def set(key, value)
      key = key.to_s
      row = find_or_initialize_by(key: key)
      row.value_type = DEFINITIONS.dig(key, :type) || row.value_type || "string"
      row.value = serialize(value, row.value_type)
      row.save!
      row
    end

    # Update many at once; raises unless all succeed.
    def bulk_update(attrs)
      transaction do
        attrs.each { |k, v| set(k, v) }
      end
    end

    def default_for(key)
      DEFINITIONS.dig(key.to_s, :default)
    end

    def definitions_for_tab(tab)
      DEFINITIONS.select { |_, d| d[:tab] == tab.to_s }
    end

    private

    def cache_key(key)
      "setting:#{key}:v#{cache_version}"
    end

    def cache_version
      Rails.cache.fetch("setting:cache_version") { 1 }
    end

    def bump_cache_version!
      Rails.cache.write("setting:cache_version", (cache_version + 1))
    end

    def coerce(raw, type)
      return nil if raw.nil?

      case type
      when "integer" then Integer(raw)
      when "boolean" then ActiveModel::Type::Boolean.new.cast(raw)
      when "json"    then JSON.parse(raw)
      else raw.to_s
      end
    end

    def serialize(value, type)
      case type
      when "json" then value.to_json
      when "boolean" then ActiveModel::Type::Boolean.new.cast(value) ? "true" : "false"
      else value.to_s
      end
    end
  end

  private

  def bust_cache
    self.class.send(:bump_cache_version!)
  end
end
