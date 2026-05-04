# Per-locale translation storage for taxonomy/chrome models (Location,
# Category, Tag, Author, StaticPage). Each model declares which attributes
# carry per-locale overrides via `translates :name, :description`. The
# parent record holds the canonical English values; a child translation
# table holds non-English overrides keyed on (locale, parent_id).
#
# Read API:
#   location.localized_name              # → translation for I18n.locale, else parent.name
#   location.localized_name(:ja)         # → explicit locale
#   location.translation_for(:ja)        # → the LocationTranslation row, or nil
#
# Why a dedicated table per model rather than JSONB or a polymorphic store:
# the Article translation flow already follows this shape, so admins, the
# admin form, and validation behavior stay consistent across the site. Per-
# locale uniqueness, indexed lookups, and `joins(:translations).where(locale:)`
# all work first-class without going through JSON operators.
module Translatable
  extend ActiveSupport::Concern

  class_methods do
    # Declares which attributes can be translated. For each attribute we
    # generate a `localized_<attr>` reader that returns the translation
    # value if present and non-blank, otherwise falls back to the parent
    # record's English value.
    #
    # Optional kwargs let a model override the default child-class /
    # foreign-key naming, but the conventions cover every current caller.
    def translates(*attrs, class_name: nil, foreign_key: nil)
      class_name  ||= "#{name}Translation"
      foreign_key ||= "#{model_name.element}_id"
      inverse     = model_name.element.to_sym

      has_many :translations, -> { order(:locale) },
               class_name: class_name,
               foreign_key: foreign_key,
               dependent: :destroy,
               inverse_of: inverse
      accepts_nested_attributes_for :translations,
                                    allow_destroy: false,
                                    reject_if: :translation_attrs_blank?

      attrs.each do |attr|
        define_method(:"localized_#{attr}") do |locale = I18n.locale|
          override = translation_for(locale)&.public_send(attr)
          override.presence || public_send(attr)
        end
      end
    end
  end

  # Find a translation for the given locale, or nil. Iterates the in-memory
  # association rather than firing a SQL query so it's cheap when callers
  # have already eager-loaded `:translations`.
  def translation_for(locale)
    locale_str = locale.to_s
    translations.find { |t| t.locale == locale_str }
  end

  private

  # Reject translation rows where every translatable field is blank. The
  # admin form submits a hidden `locale` for every active language even
  # when the editor leaves all the inputs empty, so the default
  # `:all_blank` check would never reject anything. Once a row has any
  # content we keep it; admins remove a translation by clearing every
  # field, which causes the row to be skipped on the next save.
  def translation_attrs_blank?(attrs)
    attrs.except(:id, "id", :locale, "locale", :_destroy, "_destroy").values.all?(&:blank?)
  end
end
