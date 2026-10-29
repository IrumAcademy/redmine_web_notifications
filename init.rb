require_relative 'lib/redmine_web_notifications/recorder'
require_relative 'lib/redmine_web_notifications/mailer_patch'
require_relative 'lib/redmine_web_notifications/view_hook'

Redmine::Plugin.register :redmine_web_notifications do
  name 'Redmine Web Notifications'
  author 'TrueShine'
  description 'Header bell and browser desktop notifications that follow Redmine email notification rules'
  version '0.1.0'
  url 'https://github.com/TrueShine/redmine_web_notifications'
  author_url 'https://github.com/TrueShine'
  requires_redmine version_or_higher: '6.0'

  settings default: { 'poll_interval' => '60', 'retention_days' => '90' },
           partial: 'settings/web_notifications'
end

# A user's notifications go with the user.
unless User.reflect_on_association(:web_notifications)
  User.has_many :web_notifications, dependent: :delete_all
end
