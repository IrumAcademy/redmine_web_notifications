module RedmineWebNotifications
  # Saves one notification for one recipient. Never raises: a failure here must not stop the email.
  module Recorder
    module_function

    def record(user, kind, title:, path:, notifiable: nil, project: nil, actor: nil, summary: nil)
      return unless user.is_a?(User) && user.active?
      # Mail rules may include the user's own changes; a bell for your own edit is only noise.
      return if actor && actor.id == user.id

      WebNotification.create!(
        user: user, kind: kind.to_s, notifiable: notifiable, project: project, actor: actor,
        title: title.to_s.truncate(255), summary: excerpt(summary), path: path
      )
    rescue StandardError => e
      Rails.logger.error "[redmine_web_notifications] #{kind} for user ##{user.try(:id)}: #{e.class}: #{e.message}"
      nil
    end

    def excerpt(text, length = 200)
      text = text.to_s.gsub(/\s+/, ' ').strip
      text.empty? ? nil : text.truncate(length)
    end
  end
end
