module RedmineWebNotifications
  class ViewHook < Redmine::Hook::ViewListener
    # The bell is added to the account menu by JavaScript, so it works with any theme that keeps
    # Redmine's #account menu. The first unread count is rendered here to avoid an extra request.
    def view_layouts_base_html_head(context = {})
      return '' unless User.current.logged?

      scope = WebNotification.for_user(User.current)
      config = {
        unread: scope.unread.count,
        latestId: scope.maximum(:id).to_i,
        interval: WebNotification.poll_interval,
        urls: {
          index: web_notifications_path, recent: recent_web_notifications_path,
          poll: poll_web_notifications_path, readAll: read_all_web_notifications_path
        },
        text: {
          title: l(:label_web_notifications), markAllRead: l(:label_web_notification_mark_all_read),
          viewAll: l(:label_web_notification_view_all), empty: l(:label_web_notification_empty),
          enableDesktop: l(:label_web_notification_enable_desktop),
          desktopDenied: l(:label_web_notification_desktop_denied)
        }
      }
      safe_join([
        stylesheet_link_tag('web_notifications', plugin: 'redmine_web_notifications'),
        javascript_tag("window.RedmineWebNotifications = #{config.to_json};"),
        javascript_include_tag('web_notifications', plugin: 'redmine_web_notifications', defer: true)
      ], "\n")
    end
  end
end
