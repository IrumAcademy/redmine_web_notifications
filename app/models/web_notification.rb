class WebNotification < ApplicationRecord
  KINDS = %w(
    issue_added issue_updated issue_mentioned
    wiki_added wiki_updated
    news_added news_comment
    message_posted document_added attachments_added
  ).freeze

  belongs_to :user
  belongs_to :actor, class_name: 'User', optional: true
  belongs_to :project, optional: true
  belongs_to :notifiable, polymorphic: true, optional: true

  validates :kind, inclusion: { in: KINDS }
  validates :title, :path, presence: true

  scope :for_user, ->(user) { where(user_id: user.id) }
  scope :unread, -> { where(read_at: nil) }
  scope :newest_first, -> { order(id: :desc) }

  # Purging on every insert would be wasteful; about once per 100 inserts is plenty.
  after_create_commit :purge_expired, if: -> { rand(100).zero? }

  def self.setting(name)
    Setting.plugin_redmine_web_notifications[name.to_s]
  end

  def self.poll_interval
    setting(:poll_interval).to_i.clamp(15, 3600)
  end

  def self.retention_days
    days = setting(:retention_days).to_i
    days.positive? ? days : 90
  end

  def self.mark_all_read(user)
    for_user(user).unread.update_all(read_at: Time.current)
  end

  def unread?
    read_at.nil?
  end

  def mark_read!
    update_column(:read_at, Time.current) if unread?
  end

  def ago_text
    return ::I18n.t(:label_web_notification_just_now) if created_on > 1.minute.ago

    ::I18n.t(:label_web_notification_ago,
             distance: ActionController::Base.helpers.time_ago_in_words(created_on))
  end

  def kind_label
    ::I18n.t("label_web_notification_kind_#{kind}", default: kind.humanize)
  end

  private

  def purge_expired
    self.class.where(created_on: ...self.class.retention_days.days.ago).delete_all
  end
end
