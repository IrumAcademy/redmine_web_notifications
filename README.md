# Redmine Web Notifications

A notification bell for Redmine, with optional browser desktop pop-ups.

[한국어 안내는 아래에 있습니다.](#한국어)

- A bell in the account menu shows how many notifications you haven't read.
- Clicking the bell opens a panel with your latest notifications. Clicking one opens the item and marks it read.
- A full list at `/web_notifications` has "All" and "Unread" tabs and pages through older items.
- Desktop pop-ups appear when a Redmine tab is open in the background. Each user turns them on from the panel.
- The interface is in English and Korean.

## Who gets notified

The plugin uses Redmine's own email notification rules. The bell receives exactly the notifications that Redmine sends by email:

- The admin chooses which events send notifications in *Administration → Settings → Email notifications*.
- Each user chooses what they receive in *My account → Email notifications*. This includes watched items, assigned items and @mentions.

There are no extra notification settings to keep in sync.

Two exceptions:

- You don't get a bell notification for your own changes, even if your email settings send you a copy.
- Users who turn email notifications off entirely also get no bell notifications. The bell follows the same recipient list as email.

The bell works even if email delivery isn't configured. Redmine still decides who would get each email, and that is all the plugin needs.

Supported events: new issue, issue update, @mention, new or updated wiki page, news, news comment, forum message, new document, files added.

## Requirements

- Redmine 6.0 or later
- No extra gems, background workers or Redis

## Installation

```sh
cd /path/to/redmine/plugins
git clone https://github.com/TrueShine/redmine_web_notifications.git
cd ..
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
# restart Redmine
```

With the official Docker image, put the plugin in the mounted `plugins` directory and set `REDMINE_PLUGINS_MIGRATE=1` (or run the migrate command above inside the container), then restart.

## Settings

Go to *Administration → Plugins → Redmine Web Notifications → Configure*.

| Setting | Default | Notes |
|---|---|---|
| Poll interval (seconds) | 60 | How often each open tab asks for new notifications. 15 to 3600. |
| Keep notifications for (days) | 90 | Older notifications are deleted automatically. |

## Desktop pop-ups

1. Open the bell panel and choose **Turn on desktop notifications**. The browser asks for permission.
2. After you allow it, new notifications pop up while a Redmine tab is open but not in front.
3. Click a pop-up to open the item.

Notes:

- Pop-ups need HTTPS.
- If the tab you're looking at is the Redmine tab, only the badge updates.
- With several Redmine tabs open, each notification pops up only once.
- If you blocked notifications before, allow them again in the browser's site settings.

## How it works

- Redmine calls a mailer method once per recipient, such as `Mailer#issue_add(user, issue)`. The plugin prepends these methods and saves one row per recipient in `web_notifications`, then lets the mail continue as usual.
- If saving the notification fails, the error is logged and the email is unaffected.
- The page loads with the unread count already in place. After that, each tab calls `GET /web_notifications/poll` every poll interval.
- Every request is for the logged-in user only. Other users' notifications return 404.

Polling counts as activity. If you set an idle session timeout in Redmine, an open tab keeps the session alive.

## Uninstall

```sh
bundle exec rake redmine:plugins:migrate NAME=redmine_web_notifications VERSION=0 RAILS_ENV=production
rm -rf plugins/redmine_web_notifications
# restart Redmine
```

## License

MIT. See [LICENSE](LICENSE).

---

## 한국어

Redmine 상단에 알림 종을 달아 주는 플러그인입니다. 브라우저 데스크톱 알림도 지원합니다.

- 상단 계정 메뉴의 종 아이콘에 안 읽은 알림 개수가 표시됩니다.
- 종을 누르면 최근 알림이 열립니다. 항목을 누르면 해당 일감으로 이동하고 읽음 처리됩니다.
- `/web_notifications`에서 전체 알림과 안 읽은 알림을 볼 수 있습니다.
- 다른 탭을 보고 있을 때는 데스크톱 팝업으로 알려 줍니다. 패널에서 **데스크톱 알림 켜기**를 누르면 켜집니다.

**알림 대상은 Redmine 메일 알림 규칙을 그대로 따릅니다.** 관리자 설정의 알림 이벤트와, 각자 *내 계정 → 메일 알림*에서 정한 항목(지켜보는 일감, 담당 일감, @멘션 등)에 맞춰 메일이 가는 사람에게 종 알림도 갑니다.

- 내가 한 변경은 종 알림으로 오지 않습니다.
- 메일 알림을 "받지 않음"으로 설정한 사람은 종 알림도 받지 않습니다.
- 메일 서버를 설정하지 않은 Redmine에서도 종 알림은 동작합니다.

**설치**

1. `plugins` 폴더에 이 저장소를 clone합니다.
2. `rake redmine:plugins:migrate`를 실행합니다.
3. Redmine을 재시작합니다.

Docker 공식 이미지를 쓴다면 `REDMINE_PLUGINS_MIGRATE=1` 환경변수를 두면 재시작할 때 마이그레이션이 함께 실행됩니다.

**설정**은 *관리 → 플러그인 → 설정*에 있습니다. 새 알림 확인 주기(기본 60초)와 보관 기간(기본 90일)을 바꿀 수 있습니다.
