class AuditLog < ApplicationRecord
  belongs_to :user, optional: true

  ACTIONS = %w[create update destroy].freeze

  scope :recent, -> { order(created_at: :desc) }
  scope :for_resource, ->(type, id) { where(resource_type: type, resource_id: id) }

  # Record a mutation. `resource` is normally an ActiveRecord row, but may be nil
  # for category-level events (e.g. settings saves that span several rows). In
  # that case, callers must pass an explicit `resource_type` and `label`.
  def self.record(user:, action:, resource:, label: nil, ip: nil, metadata: {}, resource_type: nil)
    create!(
      user:           user,
      action:         action.to_s,
      resource_type:  resource_type || resource&.class&.name,
      resource_id:    resource&.id,
      resource_label: label || resource&.try(:title) || resource&.try(:name) || resource&.try(:email) || (resource ? "##{resource.id}" : nil),
      metadata:       metadata,
      ip_address:     ip
    )
  rescue => e
    Rails.logger.error("[AuditLog] Failed to record: #{e.message}")
  end
end
