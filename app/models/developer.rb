class Developer < ApplicationRecord
  include Availability
  include Avatarable
  include HasSocialProfiles
  include PgSearch::Model

  enum search_status: {
    actively_looking: 1,
    open: 2,
    not_interested: 3,
    invisible: 4
  }

  AVAILABLE_STATUSES = %i[actively_looking open].freeze
  UNAVAILABLE_STATUSES = %i[not_interested].freeze

  belongs_to :user
  has_many :conversations, -> { visible }
  has_one :location, dependent: :destroy, autosave: true
  has_one :role_level, dependent: :destroy, autosave: true
  has_one :role_type, dependent: :destroy, autosave: true
  has_one_attached :cover_image

  has_noticed_notifications

  accepts_nested_attributes_for :location, reject_if: :all_blank, update_only: true
  accepts_nested_attributes_for :role_level, update_only: true
  accepts_nested_attributes_for :role_type, update_only: true

  validates :bio, presence: true
  validates :cover_image, content_type: ["image/png", "image/jpeg", "image/jpg"], max_file_size: 10.megabytes
  validates :hero, presence: true
  validates :location, presence: true, on: :create
  validates :name, presence: true

  pg_search_scope :filter_by_search_query, against: [:bio, :hero], using: {tsearch: {tsvector_column: :textsearchable_index_col}}

  scope :filter_by_role_types, ->(role_types) do
    RoleType::TYPES.filter_map { |type|
      where(role_type: {type => true}) if role_types.include?(type)
    }.reduce(:or).joins(:role_type)
  end

  scope :filter_by_role_levels, ->(role_levels) do
    RoleLevel::TYPES.filter_map { |level|
      where(role_level: {level => true}) if role_levels.include?(level)
    }.reduce(:or).joins(:role_level)
  end

  scope :filter_by_utc_offset, ->(utc_offset) do
    joins(:location).where(locations: {utc_offset:})
  end

  scope :available, -> { where(available_on: ..Time.current.to_date) }
  scope :available_first, -> { where.not(available_on: nil).order(:available_on) }
  scope :newest_first, -> { order(created_at: :desc) }
  scope :visible, -> { where.not(search_status: :invisible).or(where(search_status: nil)) }
  scope :featured, -> { where("featured_at >= ?", 1.week.ago).order(featured_at: :desc) }

  after_create_commit :send_admin_notification, :send_welcome_email
  after_commit :notify_admins_of_potential_hire, if: :changes_indicate_potential_hire?

  def visible?
    !invisible?
  end

  def location
    super || build_location
  end

  def role_level
    super || build_role_level
  end

  def role_type
    super || build_role_type
  end

  # If a check is added make sure to add a NewDeveloperFieldComponent to the developer form.
  def missing_fields?
    search_status.blank? ||
      location.missing_fields? ||
      role_level.missing_fields? ||
      role_type.missing_fields? ||
      available_on.blank?
  end

  def invisiblize!
    invisible!
    send_invisiblize_notification
  end

  def feature!
    touch(:featured_at)
  end

  def notifications_as_subject
    Notification.where("substring(n.params->'developer'->>'_aj_globalid' FROM '[0-9]+')::int = ?", id)
  end

  private

  def changes_indicate_potential_hire?
    return false unless saved_change_to_search_status?

    original_value, saved_value = saved_change_to_search_status
    AVAILABLE_STATUSES.include?(original_value) && UNAVAILABLE_STATUSES.include?(saved_value)
  end

  def notify_admins_of_potential_hire
    PotentialHireNotification.with(developer: self, reason: :search_status).deliver_later(User.admin)
  end

  def send_admin_notification
    NewDeveloperProfileNotification.with(developer: self).deliver_later(User.admin)
  end

  def send_welcome_email
    DeveloperMailer.with(developer: self).welcome_email.deliver_later
  end

  def send_invisiblize_notification
    InvisiblizeDeveloperNotification.with(developer: self).deliver_later(user)
  end
end
