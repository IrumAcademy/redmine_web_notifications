module RedmineWebNotifications
  # Redmine builds one mail per recipient (Mailer#issue_add(user, issue) and so on), after it has
  # applied the admin's notified events and each user's own mail settings. Recording here gives
  # the bell exactly the same recipients as email. The builder runs even when email delivery is
  # not configured, so the bell works on servers without SMTP too.
  module MailerPatch
    def issue_add(user, issue)
      safely do
        kind = mentioned?(issue, user, nil, issue.description) ? :issue_mentioned : :issue_added
        Recorder.record(user, kind, notifiable: issue, project: issue.project, actor: issue.author,
                        title: issue.to_s, summary: issue.description, path: path_for(issue.event_url))
      end
      super
    end

    def issue_edit(user, journal)
      safely do
        issue = journal.journalized
        kind = mentioned_in_journal?(journal, user) ? :issue_mentioned : :issue_updated
        Recorder.record(user, kind, notifiable: issue, project: issue.project, actor: journal.user,
                        title: issue.to_s, summary: journal_summary(journal),
                        path: path_for(journal.event_url))
      end
      super
    end

    def wiki_content_added(user, wiki_content)
      safely do
        record_wiki(user, :wiki_added, wiki_content)
      end
      super
    end

    def wiki_content_updated(user, wiki_content)
      safely do
        record_wiki(user, :wiki_updated, wiki_content)
      end
      super
    end

    def news_added(user, news)
      safely do
        Recorder.record(user, :news_added, notifiable: news, project: news.project, actor: news.author,
                        title: news.title, summary: news.summary.presence || news.description,
                        path: path_for(news.event_url))
      end
      super
    end

    def news_comment_added(user, comment)
      safely do
        news = comment.commented
        Recorder.record(user, :news_comment, notifiable: news, project: news.project, actor: comment.author,
                        title: news.title, summary: comment.comments, path: path_for(news.event_url))
      end
      super
    end

    def message_posted(user, message)
      safely do
        Recorder.record(user, :message_posted, notifiable: message, project: message.project,
                        actor: message.author, title: message.subject, summary: message.content,
                        path: path_for(message.event_url))
      end
      super
    end

    def document_added(user, document, author)
      safely do
        Recorder.record(user, :document_added, notifiable: document, project: document.project,
                        actor: author, title: document.title, summary: document.description,
                        path: path_for(document.event_url))
      end
      super
    end

    def attachments_added(user, attachments)
      safely do
        container = attachments.first.container
        path =
          if container.is_a?(Document)
            path_for(controller: 'documents', action: 'show', id: container.id)
          else
            path_for(controller: 'files', action: 'index', project_id: container.project)
          end
        Recorder.record(user, :attachments_added, notifiable: container, project: container.project,
                        actor: attachments.first.author, title: container.to_s,
                        summary: attachments.map(&:filename).join(', '), path: path)
      end
      super
    end

    private

    # Building a notification must never stop the mail itself.
    def safely
      yield
    rescue StandardError => e
      Rails.logger.error "[redmine_web_notifications] #{e.class}: #{e.message}"
    end

    def record_wiki(user, kind, wiki_content)
      page = wiki_content.page
      Recorder.record(user, kind, notifiable: page, project: page.project, actor: wiki_content.author,
                      title: page.pretty_title, summary: wiki_content.comments,
                      path: path_for(controller: 'wiki', action: 'show', project_id: page.project,
                                     id: page.title))
    end

    # Runs inside Mailer#process, so `l` already speaks the recipient's language.
    def journal_summary(journal)
      return journal.notes if journal.notes.present?

      if (detail = journal.details.detect { |d| d.property == 'attr' && d.prop_key == 'status_id' })
        from = IssueStatus.find_by(id: detail.old_value)
        to = IssueStatus.find_by(id: detail.value)
        return "#{l(:field_status)}: #{from} → #{to}"
      end
      if (detail = journal.details.detect { |d| d.property == 'attr' && d.prop_key == 'assigned_to_id' })
        return "#{l(:field_assigned_to)}: #{Principal.find_by(id: detail.value) || '-'}"
      end

      nil
    end

    # Redmine keeps the mentioned users only in memory on the saved record, and the mail job loads a
    # fresh copy, so the mention is found again here with Redmine's own parser.
    def mentioned?(record, user, old_text, new_text)
      return false unless record.respond_to?(:scan_for_mentioned_users, true)

      added = record.send(:scan_for_mentioned_users, new_text) - record.send(:scan_for_mentioned_users, old_text)
      added.any? { |login| login.casecmp?(user.login) }
    rescue StandardError
      false
    end

    def mentioned_in_journal?(journal, user)
      return true if mentioned?(journal, user, nil, journal.notes)

      detail = journal.details.detect { |d| d.property == 'attr' && d.prop_key == 'description' }
      detail.present? && mentioned?(journal.journalized, user, detail.old_value, detail.value)
    end

    # Same host prefix handling as the links in Redmine's own mails, minus the host.
    def path_for(options)
      url_for(options.merge(only_path: true))
    end
  end
end

Mailer.prepend RedmineWebNotifications::MailerPatch unless Mailer <= RedmineWebNotifications::MailerPatch
