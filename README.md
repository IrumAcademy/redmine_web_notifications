# Redmine Web Notifications

A notification bell for Redmine, with optional browser desktop pop-ups.

[한국어 안내는 아래에 있습니다.](#한국어)

- A bell in the top bar shows how many notifications you haven't read. On Redmine 7 it sits next to the avatar menu; on phones, next to the menu button.
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

- Redmine 6.0 or later (tested on 6.0.11 and 7.0.3)
- No extra gems, background workers or Redis

## Installation

```sh
cd /path/to/redmine/plugins
git clone https://github.com/IrumAcademy/redmine_web_notifications.git
cd ..
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
# restart Redmine
```

With the official Docker image, put the plugin in the mounted `plugins` directory and set `REDMINE_PLUGINS_MIGRATE=1` (or run the migrate command above inside the container), then restart.

## Installing with an AI assistant

Copy the prompt below into an AI coding assistant (Claude Code, Codex and so on) that can run commands on your Redmine server.

```text
Install the "Redmine Web Notifications" plugin on this server's Redmine.

Repository: https://github.com/IrumAcademy/redmine_web_notifications

Steps:
1. Find out how Redmine is installed: directly (a Redmine folder with a plugins/ directory) or with Docker
   (the official redmine image and a docker-compose.yml). If unsure, ask me.
   Check that Redmine is 6.0 or later.
2. Back up the database before changing anything (for PostgreSQL: pg_dump -Fc; for MySQL: mysqldump),
   and back up the compose file if you will edit it.
3. Clone the repository into the plugins folder as plugins/redmine_web_notifications.
   For Docker, use the folder that is mounted at /usr/src/redmine/plugins. If plugins are not mounted,
   add a mount for the plugin folder to the redmine service.
4. Read init.rb, lib/ and assets/javascripts/web_notifications.js and check that the plugin makes no
   external network requests and adds no gems.
5. Run the plugin migration: bundle exec rake redmine:plugins:migrate RAILS_ENV=production
   (for Docker: set REDMINE_PLUGINS_MIGRATE=1 on the redmine service, or run the command in the container).
6. Restart only Redmine (for Docker: docker compose up -d <redmine service>). Leave other services alone.
7. Check the logs for errors, and check that Administration → Plugins lists "Redmine Web Notifications".
8. Tell me where the bell appears, where the settings are (Administration → Plugins → Configure),
   and how to uninstall (migrate NAME=redmine_web_notifications VERSION=0, remove the folder, restart).
```

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

- 상단의 종 아이콘에 안 읽은 알림 개수가 표시됩니다. Redmine 7 에서는 프로필 아이콘 옆, 휴대폰에서는 메뉴 버튼 옆에 나옵니다.
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

**AI 도우미로 설치하기**

아래 프롬프트를 복사해서, Redmine 서버에서 명령을 실행할 수 있는 AI 코딩 도우미(Claude Code, Codex 등)에 붙여 넣으세요.

```text
이 서버의 Redmine 에 "Redmine Web Notifications" 플러그인을 설치해 줘.

저장소: https://github.com/IrumAcademy/redmine_web_notifications

순서:
1. Redmine 이 어떻게 설치돼 있는지 찾아. 직접 설치(Redmine 폴더 안에 plugins/ 가 있음)인지,
   Docker(공식 redmine 이미지, docker-compose.yml)인지 확인하고, 모르겠으면 나에게 물어봐.
   Redmine 버전이 6.0 이상인지도 확인해.
2. 바꾸기 전에 DB 를 백업해 (PostgreSQL 이면 pg_dump -Fc, MySQL 이면 mysqldump).
   compose 파일을 고친다면 그 파일도 백업해.
3. 저장소를 plugins/redmine_web_notifications 라는 이름으로 clone 해.
   Docker 라면 /usr/src/redmine/plugins 에 마운트된 폴더에 넣고, 플러그인 폴더가 마운트돼 있지 않으면
   redmine 서비스에 마운트를 추가해.
4. init.rb, lib/, assets/javascripts/web_notifications.js 를 읽어서 외부 네트워크 요청이 없고
   추가 gem 이 없는지 확인해.
5. 플러그인 마이그레이션을 실행해: bundle exec rake redmine:plugins:migrate RAILS_ENV=production
   (Docker 면 redmine 서비스에 REDMINE_PLUGINS_MIGRATE=1 을 두거나 컨테이너 안에서 이 명령을 실행).
6. Redmine 만 재시작해 (Docker 면 docker compose up -d <redmine 서비스>). 다른 서비스는 건드리지 마.
7. 로그에 오류가 없는지, 관리 → 플러그인 에 "Redmine Web Notifications" 가 보이는지 확인해.
8. 종 아이콘이 어디에 나오는지, 설정 위치(관리 → 플러그인 → 설정),
   제거 방법(migrate NAME=redmine_web_notifications VERSION=0, 폴더 삭제, 재시작)을 알려 줘.
```

**설정**은 *관리 → 플러그인 → 설정*에 있습니다. 새 알림 확인 주기(기본 60초)와 보관 기간(기본 90일)을 바꿀 수 있습니다.
