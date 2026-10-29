class WebNotificationsController < ApplicationController
  before_action :require_login
  before_action :find_notification, only: [:show, :read]

  def index
    scope = WebNotification.for_user(User.current)
    @filter = params[:filter] == 'unread' ? 'unread' : 'all'
    @unread_count = scope.unread.count
    scope = scope.unread if @filter == 'unread'

    @limit = per_page_option
    @count = scope.count
    @paginator = Redmine::Pagination::Paginator.new(@count, @limit, params['page'])
    @notifications = scope.includes(:project, :actor).newest_first
                          .limit(@limit).offset(@paginator.offset).to_a
  end

  # Opening a notification marks it read and goes to the issue, wiki page, etc.
  def show
    @notification.mark_read!
    redirect_to @notification.path
  end

  # Items for the bell's drop-down panel.
  def recent
    scope = WebNotification.for_user(User.current)
    items = scope.includes(:project, :actor).newest_first.limit(10)
    render json: { unread: scope.unread.count, items: items.map { |n| item_json(n) } }
  end

  # Called every poll interval by each open tab, so it stays small: the unread count, plus the
  # unread items newer than `since` (for desktop pop-ups).
  def poll
    scope = WebNotification.for_user(User.current)
    since = params[:since].to_i
    fresh = since.positive? ? scope.unread.where('id > ?', since).includes(:project, :actor).order(:id).limit(5) : []
    render json: { unread: scope.unread.count, latest_id: scope.maximum(:id).to_i,
                   fresh: fresh.map { |n| item_json(n) } }
  end

  def read
    @notification.mark_read!
    respond_to do |format|
      format.html { redirect_back_or_default web_notifications_path }
      format.json { render json: { unread: WebNotification.for_user(User.current).unread.count } }
    end
  end

  def read_all
    WebNotification.mark_all_read(User.current)
    respond_to do |format|
      format.html { redirect_back_or_default web_notifications_path }
      format.json { render json: { unread: 0 } }
    end
  end

  private

  def find_notification
    @notification = WebNotification.for_user(User.current).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def item_json(notification)
    {
      id: notification.id,
      kind: notification.kind_label,
      title: notification.title,
      summary: notification.summary,
      project: notification.project&.name,
      actor: notification.actor&.name,
      ago: notification.ago_text,
      url: web_notification_path(notification),
      unread: notification.unread?
    }
  end
end
