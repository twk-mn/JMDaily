class Ad < ApplicationRecord
  has_one_attached :image

  PLACEMENT_ZONES = %w[
    header_banner
    article_inline
    article_footer
    homepage_mid
    category_mid
    footer_banner
  ].freeze

  ZONE_LABELS = {
    "header_banner"  => "Header Banner (below nav)",
    "article_inline" => "Article — Inline (after intro)",
    "article_footer" => "Article — Footer (below body)",
    "homepage_mid"   => "Homepage — Mid (below lead story)",
    "category_mid"   => "Category Pages — Mid",
    "footer_banner"  => "Footer Banner (above site footer)"
  }.freeze

  AD_TYPES = %w[direct adsense custom_html].freeze
  STATUSES = %w[active paused archived].freeze

  validates :name, presence: true
  validates :ad_type, inclusion: { in: AD_TYPES }
  validates :placement_zone, inclusion: { in: PLACEMENT_ZONES }
  validates :status, inclusion: { in: STATUSES }
  validates :link_url, presence: true, if: -> { ad_type == "direct" }
  validates :link_url, format: { with: /\Ahttps?:\/\/.+\z/i, message: "must start with http:// or https://" },
                       allow_blank: true
  validates :script_code, presence: true, if: -> { ad_type.in?(%w[adsense custom_html]) }
  validate :ends_at_after_starts_at

  scope :active_status, -> { where(status: "active") }
  scope :for_zone, ->(zone) { where(placement_zone: zone) }
  scope :currently_running, -> {
    active_status
      .where("starts_at IS NULL OR starts_at <= ?", Time.current)
      .where("ends_at IS NULL OR ends_at >= ?", Time.current)
  }

  def self.pick_for_zone(zone)
    for_zone(zone).currently_running.order(priority: :desc).first
  end

  def zone_label
    ZONE_LABELS[placement_zone] || placement_zone
  end

  def active?
    status == "active"
  end

  def running?
    active? &&
      (starts_at.nil? || starts_at <= Time.current) &&
      (ends_at.nil? || ends_at >= Time.current)
  end

  private

  def ends_at_after_starts_at
    return unless starts_at.present? && ends_at.present?
    errors.add(:ends_at, "must be after start date") if ends_at <= starts_at
  end
end
