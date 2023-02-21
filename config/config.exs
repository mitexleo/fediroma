#                                 .i;;;;i.
#                               iYcviii;vXY:
#                             .YXi       .i1c.
#                            .YC.     .    in7.
#                           .vc.   ......   ;1c.
#                           i7,   ..        .;1;
#                          i7,   .. ...      .Y1i
#                         ,7v     .6MMM@;     .YX,
#                        .7;.   ..IMMMMMM1     :t7.
#                       .;Y.     ;$MMMMMM9.     :tc.
#                       vY.   .. .nMMM@MMU.      ;1v.
#                      i7i   ...  .#MM@M@C. .....:71i
#                     it:   ....   $MMM@9;.,i;;;i,;tti
#                    :t7.  .....   0MMMWv.,iii:::,,;St.
#                   .nC.   .....   IMMMQ..,::::::,.,czX.
#                  .ct:   ....... .ZMMMI..,:::::::,,:76Y.
#                  c2:   ......,i..Y$M@t..:::::::,,..inZY
#                 vov   ......:ii..c$MBc..,,,,,,,,,,..iI9i
#                i9Y   ......iii:..7@MA,..,,,,,,,,,....;AA:
#               iIS.  ......:ii::..;@MI....,............;Ez.
#              .I9.  ......:i::::...8M1..................C0z.
#             .z9;  ......:i::::,.. .i:...................zWX.
#             vbv  ......,i::::,,.      ................. :AQY
#            c6Y.  .,...,::::,,..:t0@@QY. ................ :8bi
#           :6S. ..,,...,:::,,,..EMMMMMMI. ............... .;bZ,
#          :6o,  .,,,,..:::,,,..i#MMMMMM#v.................  YW2.
#         .n8i ..,,,,,,,::,,,,.. tMMMMM@C:.................. .1Wn
#         7Uc. .:::,,,,,::,,,,..   i1t;,..................... .UEi
#         7C...::::::::::::,,,,..        ....................  vSi.
#         ;1;...,,::::::,.........       ..................    Yz:
#          v97,.........                                     .voC.
#           izAotX7777777777777777777777777777777777777777Y7n92:
#             .;CoIIIIIUAA666666699999ZZZZZZZZZZZZZZZZZZZZ6ov.
#
#                          !!! ATTENTION !!!
# DO NOT EDIT THIS FILE! THIS FILE CONTAINS THE DEFAULT VALUES FOR THE CON-
# FIGURATION! EDIT YOUR SECRET FILE (either prod.secret.exs, dev.secret.exs).
#
# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

# General application configuration
config :pleroma, ecto_repos: [Pleroma.Repo]

config :pleroma, Pleroma.Repo,
  telemetry_event: [Pleroma.Repo.Instrumenter],
  queue_target: 20_000,
  migration_lock: nil

config :pleroma, Pleroma.Captcha,
  enabled: true,
  seconds_valid: 300,
  method: Pleroma.Captcha.Native

config :pleroma, Pleroma.Captcha.Kocaptcha, endpoint: "https://captcha.kotobank.ch"

# Upload configuration
config :pleroma, Pleroma.Upload,
  uploader: Pleroma.Uploaders.Local,
  filters: [Pleroma.Upload.Filter.Dedupe],
  link_name: false,
  proxy_remote: false,
  filename_display_max_length: 30,
  default_description: nil,
  base_url: nil

config :pleroma, Pleroma.Uploaders.Local, uploads: "uploads"

config :pleroma, Pleroma.Uploaders.S3,
  bucket: nil,
  bucket_namespace: nil,
  truncated_namespace: nil,
  streaming_enabled: true

config :ex_aws, :s3,
  # host: "s3.wasabisys.com", # required if not Amazon AWS
  access_key_id: nil,
  secret_access_key: nil,
  # region: "us-east-1", # may be required for Amazon AWS
  scheme: "https://"

config :pleroma, :emoji,
  shortcode_globs: ["/emoji/custom/**/*.png"],
  pack_extensions: [".png", ".gif"],
  groups: [
    Custom: ["/emoji/*.png", "/emoji/**/*.png"]
  ],
  default_manifest: "https://git.pleroma.social/pleroma/emoji-index/raw/master/index.json",
  shared_pack_cache_seconds_per_file: 60

config :pleroma, :uri_schemes,
  valid_schemes: [
    "https",
    "http",
    "dat",
    "dweb",
    "gopher",
    "hyper",
    "ipfs",
    "ipns",
    "irc",
    "ircs",
    "magnet",
    "mailto",
    "mumble",
    "ssb",
    "xmpp"
  ]

websocket_config = [
  path: "/websocket",
  serializer: [
    {Phoenix.Socket.V1.JSONSerializer, "~> 1.0.0"},
    {Phoenix.Socket.V2.JSONSerializer, "~> 2.0.0"}
  ],
  timeout: 60_000,
  transport_log: false,
  compress: false
]

# Configures the endpoint
config :pleroma, Pleroma.Web.Endpoint,
  url: [host: "localhost"],
  http: [
    ip: {127, 0, 0, 1},
    dispatch: [
      {:_,
       [
         {"/api/v1/streaming", Pleroma.Web.MastodonAPI.WebsocketHandler, []},
         {"/websocket", Phoenix.Endpoint.CowboyWebSocket,
          {Phoenix.Transports.WebSocket,
           {Pleroma.Web.Endpoint, Pleroma.Web.UserSocket, websocket_config}}},
         {:_, Phoenix.Endpoint.Cowboy2Handler, {Pleroma.Web.Endpoint, []}}
       ]}
    ]
  ],
  protocol: "https",
  secret_key_base: "aK4Abxf29xU9TTDKre9coZPUgevcVCFQJe/5xP/7Lt4BEif6idBIbjupVbOrbKxl",
  live_view: [signing_salt: "U5ELgdEwTD3n1+D5s0rY0AMg8/y1STxZ3Zvsl3bWh+oBcGrYdil0rXqPMRd3Glcq"],
  signing_salt: "CqaoopA2",
  render_errors: [view: Pleroma.Web.ErrorView, accepts: ~w(json)],
  pubsub_server: Pleroma.PubSub,
  secure_cookie_flag: true,
  extra_cookie_attrs: [
    "SameSite=Lax"
  ]

# Configures Elixir's Logger
config :logger, truncate: 65_536

config :logger, :console,
  level: :info,
  format: "\n$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :logger, :ex_syslogger,
  level: :info,
  ident: "pleroma",
  format: "$metadata[$level] $message",
  metadata: [:request_id]

config :mime, :types, %{
  "application/xml" => ["xml"],
  "application/xrd+xml" => ["xrd+xml"],
  "application/jrd+json" => ["jrd+json"],
  "application/activity+json" => ["activity+json"],
  "application/ld+json" => ["activity+json"]
}

config :tesla, :adapter, {Tesla.Adapter.Finch, name: MyFinch}

# Configures http settings, upstream proxy etc.
config :pleroma, :http,
  pool_timeout: :timer.seconds(5),
  receive_timeout: :timer.seconds(15),
  proxy_url: nil,
  user_agent: :default,
  pool_size: 50,
  adapter: []

config :pleroma, :instance,
  name: "Akkoma",
  email: "example@example.com",
  notify_email: "noreply@example.com",
  description: "Akkoma: The cooler fediverse server",
  background_image: "/images/city.jpg",
  instance_thumbnail: "/instance/thumbnail.jpeg",
  limit: 5_000,
  description_limit: 5_000,
  remote_limit: 100_000,
  upload_limit: 16_000_000,
  avatar_upload_limit: 2_000_000,
  background_upload_limit: 4_000_000,
  banner_upload_limit: 4_000_000,
  languages: ["en"],
  poll_limits: %{
    max_options: 20,
    max_option_chars: 200,
    min_expiration: 0,
    max_expiration: 365 * 24 * 60 * 60
  },
  registrations_open: true,
  invites_enabled: false,
  account_activation_required: false,
  account_approval_required: false,
  federating: true,
  federation_incoming_replies_max_depth: 100,
  federation_reachability_timeout_days: 7,
  federation_publisher_modules: [
    Pleroma.Web.ActivityPub.Publisher
  ],
  allow_relay: false,
  public: true,
  static_dir: "instance/static/",
  allowed_post_formats: [
    "text/plain",
    "text/html",
    "text/markdown",
    "text/bbcode",
    "text/x.misskeymarkdown"
  ],
  staff_transparency: [],
  autofollowed_nicknames: [],
  autofollowing_nicknames: [],
  max_pinned_statuses: 1,
  attachment_links: false,
  max_report_comment_size: 1000,
  safe_dm_mentions: false,
  healthcheck: false,
  remote_post_retention_days: 90,
  skip_thread_containment: true,
  limit_to_local_content: :unauthenticated,
  user_bio_length: 5000,
  user_name_length: 100,
  max_account_fields: 10,
  max_remote_account_fields: 20,
  account_field_name_length: 512,
  account_field_value_length: 2048,
  registration_reason_length: 500,
  external_user_synchronization: true,
  extended_nickname_format: true,
  cleanup_attachments: false,
  multi_factor_authentication: [
    totp: [
      # digits 6 or 8
      digits: 6,
      period: 30
    ],
    backup_codes: [
      number: 5,
      length: 16
    ]
  ],
  show_reactions: true,
  password_reset_token_validity: 60 * 60 * 24,
  profile_directory: true,
  privileged_staff: false,
  local_bubble: [],
  max_frontend_settings_json_chars: 100_000,
  export_prometheus_metrics: true

config :pleroma, :welcome,
  direct_message: [
    enabled: false,
    sender_nickname: nil,
    message: nil
  ],
  email: [
    enabled: false,
    sender: nil,
    subject: "Welcome to <%= instance_name %>",
    html: "Welcome to <%= instance_name %>",
    text: "Welcome to <%= instance_name %>"
  ]

config :pleroma, :feed,
  post_title: %{
    max_length: 100,
    omission: "..."
  }

config :pleroma, :markup,
  # XXX - unfortunately, inline images must be enabled by default right now, because
  # of custom emoji.  Issue #275 discusses defanging that somehow.
  allow_inline_images: true,
  allow_headings: false,
  allow_tables: false,
  allow_fonts: false,
  scrub_policy: [
    Pleroma.HTML.Scrubber.Default,
    Pleroma.HTML.Transform.MediaProxy
  ]

config :pleroma, :frontend_configurations,
  pleroma_fe: %{
    alwaysShowSubjectInput: true,
    background: "/images/city.jpg",
    collapseMessageWithSubject: false,
    disableChat: false,
    greentext: false,
    hideFilteredStatuses: false,
    hideMutedPosts: false,
    hidePostStats: false,
    hideSitename: false,
    hideUserStats: false,
    loginMethod: "password",
    logo: "/static/logo.svg",
    logoMargin: ".1em",
    logoMask: true,
    noAttachmentLinks: false,
    nsfwCensorImage: "",
    postContentType: "text/plain",
    redirectRootLogin: "/main/friends",
    redirectRootNoLogin: "/main/public",
    scopeCopy: true,
    sidebarRight: false,
    showFeaturesPanel: true,
    showInstanceSpecificPanel: false,
    subjectLineBehavior: "email",
    theme: "pleroma-dark",
    webPushNotifications: false,
    conversationDisplay: "linear"
  },
  masto_fe: %{
    showInstanceSpecificPanel: true
  }

config :pleroma, :assets,
  mascots: [
    pleroma_fox_tan: %{
      url: "/images/pleroma-fox-tan-smol.png",
      mime_type: "image/png"
    },
    pleroma_fox_tan_shy: %{
      url: "/images/pleroma-fox-tan-shy.png",
      mime_type: "image/png"
    }
  ],
  default_mascot: :pleroma_fox_tan

config :pleroma, :manifest,
  icons: [
    %{
      src: "/static/logo.svg",
      type: "image/svg+xml"
    }
  ],
  theme_color: "#282c37",
  background_color: "#191b22"

config :pleroma, :activitypub,
  unfollow_blocked: true,
  outgoing_blocks: false,
  blockers_visible: true,
  follow_handshake_timeout: 500,
  note_replies_output_limit: 5,
  sign_object_fetches: true,
  authorized_fetch_mode: false,
  max_collection_objects: 50

config :pleroma, :streamer,
  workers: 3,
  overflow_workers: 2

config :pleroma, :user, deny_follow_blocked: true

config :pleroma, :mrf_normalize_markup, scrub_policy: Pleroma.HTML.Scrubber.Default

config :pleroma, :mrf_rejectnonpublic,
  allow_followersonly: false,
  allow_direct: false

config :pleroma, :mrf_hellthread,
  delist_threshold: 10,
  reject_threshold: 20

config :pleroma, :mrf_simple,
  media_removal: [],
  media_nsfw: [],
  federated_timeline_removal: [],
  report_removal: [],
  reject: [],
  followers_only: [],
  accept: [],
  avatar_removal: [],
  banner_removal: [],
  reject_deletes: [],
  handle_threads: true

config :pleroma, :mrf_keyword,
  reject: [],
  federated_timeline_removal: [],
  replace: []

config :pleroma, :mrf_hashtag,
  sensitive: ["nsfw"],
  reject: [],
  federated_timeline_removal: []

config :pleroma, :mrf_subchain, match_actor: %{}

config :pleroma, :mrf_activity_expiration, days: 365

config :pleroma, :mrf_vocabulary,
  accept: [],
  reject: []

config :pleroma, :mrf_inline_quote, prefix: "RE"

# threshold of 7 days
config :pleroma, :mrf_object_age,
  threshold: 604_800,
  actions: [:delist, :strip_followers]

config :pleroma, :mrf_follow_bot, follower_nickname: nil

config :pleroma, :rich_media,
  enabled: true,
  ignore_hosts: [],
  ignore_tld: ["local", "localdomain", "lan"],
  parsers: [
    Pleroma.Web.RichMedia.Parsers.TwitterCard,
    Pleroma.Web.RichMedia.Parsers.OEmbed
  ],
  failure_backoff: :timer.minutes(20),
  ttl_setters: [Pleroma.Web.RichMedia.Parser.TTL.AwsSignedUrl]

config :pleroma, :media_proxy,
  enabled: false,
  invalidation: [
    enabled: false,
    provider: Pleroma.Web.MediaProxy.Invalidation.Script
  ],
  proxy_opts: [
    redirect_on_failure: false,
    max_body_length: 25 * 1_048_576,
    # Note: max_read_duration defaults to Pleroma.ReverseProxy.max_read_duration_default/1
    max_read_duration: 30_000
  ],
  whitelist: []

config :pleroma, Pleroma.Web.MediaProxy.Invalidation.Http,
  method: :purge,
  headers: [],
  options: []

config :pleroma, Pleroma.Web.MediaProxy.Invalidation.Script,
  script_path: nil,
  url_format: nil

# Note: media preview proxy depends on media proxy to be enabled
config :pleroma, :media_preview_proxy,
  enabled: false,
  thumbnail_max_width: 600,
  thumbnail_max_height: 600,
  image_quality: 85,
  min_content_length: 100 * 1024

config :pleroma, :shout,
  enabled: true,
  limit: 5_000

config :phoenix, :format_encoders, json: Jason, "activity+json": Jason

config :phoenix, :json_library, Jason

config :phoenix, :filter_parameters, ["password", "confirm"]

config :pleroma, Pleroma.Web.Metadata,
  providers: [
    Pleroma.Web.Metadata.Providers.OpenGraph,
    Pleroma.Web.Metadata.Providers.TwitterCard
  ],
  unfurl_nsfw: false

config :pleroma, Pleroma.Web.Metadata.Providers.Theme, theme_color: "#593196"

config :pleroma, Pleroma.Web.Preload,
  providers: [
    Pleroma.Web.Preload.Providers.Instance
  ]

config :pleroma, :http_security,
  enabled: true,
  sts: false,
  sts_max_age: 63_072_000,
  referrer_policy: "same-origin"

config :cors_plug,
  max_age: 86_400,
  methods: ["POST", "PUT", "DELETE", "GET", "PATCH", "OPTIONS"],
  expose: [
    "Link",
    "X-RateLimit-Reset",
    "X-RateLimit-Limit",
    "X-RateLimit-Remaining",
    "X-Request-Id",
    "Idempotency-Key"
  ],
  credentials: true,
  headers: ["Authorization", "Content-Type", "Idempotency-Key"]

config :pleroma, Pleroma.User,
  restricted_nicknames: [
    ".well-known",
    "~",
    "about",
    "activities",
    "api",
    "auth",
    "check_password",
    "dev",
    "friend-requests",
    "inbox",
    "internal",
    "main",
    "media",
    "nodeinfo",
    "notice",
    "oauth",
    "objects",
    "ostatus_subscribe",
    "pleroma",
    "proxy",
    "push",
    "registration",
    "relay",
    "settings",
    "status",
    "tag",
    "user-search",
    "user_exists",
    "users",
    "web",
    "verify_credentials",
    "update_credentials",
    "relationships",
    "search",
    "confirmation_resend",
    "mfa"
  ],
  email_blacklist: []

config :pleroma, Oban,
  repo: Pleroma.Repo,
  log: false,
  queues: [
    activity_expiration: 10,
    token_expiration: 5,
    filter_expiration: 1,
    backup: 1,
    federator_incoming: 50,
    federator_outgoing: 50,
    ingestion_queue: 50,
    web_push: 50,
    mailer: 10,
    transmogrifier: 20,
    scheduled_activities: 10,
    poll_notifications: 10,
    background: 5,
    remote_fetcher: 2,
    attachments_cleanup: 1,
    new_users_digest: 1,
    mute_expire: 5,
    search_indexing: 10,
    nodeinfo_fetcher: 1,
    database_prune: 1,
    reply_refresher: 50,
  ],
  plugins: [
    Oban.Plugins.Pruner,
    {Oban.Plugins.Reindexer, schedule: "@weekly"}
  ],
  crontab: [
    {"0 0 * * 0", Pleroma.Workers.Cron.DigestEmailsWorker},
    {"0 0 * * *", Pleroma.Workers.Cron.NewUsersDigestWorker},
    {"0 3 * * *", Pleroma.Workers.Cron.PruneDatabaseWorker}
  ]

config :pleroma, :workers,
  retries: [
    federator_incoming: 5,
    federator_outgoing: 5,
    search_indexing: 2
  ],
  timeout: [
    activity_expiration: :timer.seconds(5),
    token_expiration: :timer.seconds(5),
    filter_expiration: :timer.seconds(5),
    backup: :timer.seconds(900),
    federator_incoming: :timer.seconds(10),
    federator_outgoing: :timer.seconds(10),
    ingestion_queue: :timer.seconds(5),
    web_push: :timer.seconds(5),
    mailer: :timer.seconds(5),
    transmogrifier: :timer.seconds(5),
    scheduled_activities: :timer.seconds(5),
    poll_notifications: :timer.seconds(5),
    background: :timer.seconds(5),
    remote_fetcher: :timer.seconds(10),
    attachments_cleanup: :timer.seconds(900),
    new_users_digest: :timer.seconds(10),
    mute_expire: :timer.seconds(5),
    search_indexing: :timer.seconds(5),
    nodeinfo_fetcher: :timer.seconds(10),
    database_prune: :timer.minutes(10)
  ]

config :pleroma, Pleroma.Formatter,
  class: false,
  rel: "ugc",
  new_window: false,
  truncate: false,
  strip_prefix: false,
  extra: true,
  validate_tld: :no_scheme

config :pleroma, :ldap,
  enabled: System.get_env("LDAP_ENABLED") == "true",
  host: System.get_env("LDAP_HOST") || "localhost",
  port: String.to_integer(System.get_env("LDAP_PORT") || "389"),
  ssl: System.get_env("LDAP_SSL") == "true",
  sslopts: [],
  tls: System.get_env("LDAP_TLS") == "true",
  tlsopts: [],
  base: System.get_env("LDAP_BASE") || "dc=example,dc=com",
  uid: System.get_env("LDAP_UID") || "cn"

oauth_consumer_strategies =
  "OAUTH_CONSUMER_STRATEGIES"
  |> System.get_env()
  |> to_string()
  |> String.split()
  |> Enum.map(&hd(String.split(&1, ":")))

ueberauth_providers =
  for strategy <- oauth_consumer_strategies do
    strategy_module_name = "Elixir.Ueberauth.Strategy.#{String.capitalize(strategy)}"
    strategy_module = String.to_atom(strategy_module_name)
    {String.to_atom(strategy), {strategy_module, [callback_params: ["state"]]}}
  end

config :ueberauth,
       Ueberauth,
       base_path: "/oauth",
       providers: ueberauth_providers

config :pleroma, :auth, oauth_consumer_strategies: oauth_consumer_strategies

config :pleroma, Pleroma.Emails.Mailer, adapter: Swoosh.Adapters.Sendmail, enabled: false

config :swoosh,
  api_client: Swoosh.ApiClient.Finch,
  finch_name: MyFinch

config :pleroma, Pleroma.Emails.UserEmail,
  logo: nil,
  styling: %{
    link_color: "#d8a070",
    background_color: "#2C3645",
    content_background_color: "#1B2635",
    header_color: "#d8a070",
    text_color: "#b9b9ba",
    text_muted_color: "#b9b9ba"
  }

config :pleroma, Pleroma.Emails.NewUsersDigestEmail, enabled: false

config :pleroma, Pleroma.ScheduledActivity,
  daily_user_limit: 25,
  total_user_limit: 300,
  enabled: true

config :pleroma, :email_notifications,
  digest: %{
    active: false,
    interval: 7,
    inactivity_threshold: 7
  }

config :pleroma, :oauth2,
  token_expires_in: 3600 * 24 * 365 * 100,
  issue_new_refresh_token: true,
  clean_expired_tokens: false

config :pleroma, :database, rum_enabled: false

config :pleroma, :features, improved_hashtag_timeline: :auto

config :pleroma, :populate_hashtags_table, fault_rate_allowance: 0.01

config :pleroma, :env, Mix.env()

config :http_signatures,
  adapter: Pleroma.Signature

config :pleroma, :rate_limit,
  authentication: {60_000, 15},
  timeline: {500, 3},
  search: [{1000, 10}, {1000, 30}],
  app_account_creation: {1_800_000, 25},
  relations_actions: {10_000, 10},
  relation_id_action: {60_000, 2},
  statuses_actions: {10_000, 15},
  status_id_action: {60_000, 3},
  password_reset: {1_800_000, 5},
  account_confirmation_resend: {8_640_000, 5},
  ap_routes: {60_000, 15}

config :pleroma, Pleroma.Workers.PurgeExpiredActivity, enabled: true, min_lifetime: 600

config :pleroma, Pleroma.Web.Plugs.RemoteIp,
  enabled: true,
  headers: ["x-forwarded-for"],
  proxies: [],
  reserved: [
    "127.0.0.0/8",
    "::1/128",
    "fc00::/7",
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16"
  ]

config :pleroma, :static_fe, enabled: false

# Example of frontend configuration
# This example will make us serve the primary frontend from the
# frontends directory within your `:pleroma, :instance, static_dir`.
# e.g., instance/static/frontends/pleroma/develop/
#
# With no frontend configuration, the bundled files from the `static` directory will
# be used.
#
# config :pleroma, :frontends,
# primary: %{"name" => "pleroma-fe", "ref" => "develop"},
# admin: %{"name" => "admin-fe", "ref" => "stable"},
# mastodon: %{"enabled" => true, "name" => "mastodon-fe", "ref" => "develop"}
# available: %{...}

config :pleroma, :frontends,
  primary: %{"name" => "pleroma-fe", "ref" => "stable"},
  admin: %{"name" => "admin-fe", "ref" => "stable"},
  mastodon: %{"name" => "mastodon-fe", "ref" => "akkoma"},
  swagger: %{
    "name" => "swagger-ui",
    "ref" => "stable",
    "enabled" => false
  },
  available: %{
    "pleroma-fe" => %{
      "name" => "pleroma-fe",
      "git" => "https://akkoma.dev/AkkomaGang/pleroma-fe",
      "build_url" =>
        "https://akkoma-updates.s3-website.fr-par.scw.cloud/frontend/${ref}/akkoma-fe.zip",
      "ref" => "stable",
      "build_dir" => "dist"
    },
    # Mastodon-Fe cannot be set as a primary - this is only here so we can update this seperately
    "mastodon-fe" => %{
      "name" => "mastodon-fe",
      "git" => "https://akkoma.dev/AkkomaGang/masto-fe",
      "build_url" =>
        "https://akkoma-updates.s3-website.fr-par.scw.cloud/frontend/${ref}/masto-fe.zip",
      "build_dir" => "distribution",
      "ref" => "akkoma"
    },
    "fedibird-fe" => %{
      "name" => "fedibird-fe",
      "git" => "https://akkoma.dev/AkkomaGang/fedibird-fe",
      "build_url" =>
        "https://akkoma-updates.s3-website.fr-par.scw.cloud/frontend/${ref}/fedibird-fe.zip",
      "build_dir" => "distribution",
      "ref" => "akkoma"
    },
    "admin-fe" => %{
      "name" => "admin-fe",
      "git" => "https://akkoma.dev/AkkomaGang/admin-fe",
      "build_url" =>
        "https://akkoma-updates.s3-website.fr-par.scw.cloud/frontend/${ref}/admin-fe.zip",
      "ref" => "stable"
    },
    # For developers - enables a swagger frontend to view the openapi spec
    "swagger-ui" => %{
      "name" => "swagger-ui",
      "git" => "https://github.com/swagger-api/swagger-ui",
      "build_url" => "https://akkoma-updates.s3-website.fr-par.scw.cloud/frontend/swagger-ui.zip",
      "build_dir" => "dist",
      "ref" => "stable"
    }
  }

config :pleroma, :web_cache_ttl,
  activity_pub: nil,
  activity_pub_question: 30_000

config :pleroma, :modules, runtime_dir: "instance/modules"

config :pleroma, configurable_from_database: false

config :pleroma, Pleroma.Repo,
  parameters: [gin_fuzzy_search_limit: "500"],
  prepare: :unnamed

config :pleroma, :majic_pool, size: 2

private_instance? = :if_instance_is_private

config :pleroma, :restrict_unauthenticated,
  timelines: %{local: private_instance?, federated: private_instance?},
  profiles: %{local: private_instance?, remote: private_instance?},
  activities: %{local: private_instance?, remote: private_instance?}

config :pleroma, Pleroma.Web.ApiSpec.CastAndValidate, strict: false

config :pleroma, :mrf,
  policies: [Pleroma.Web.ActivityPub.MRF.ObjectAgePolicy, Pleroma.Web.ActivityPub.MRF.TagPolicy],
  transparency: true,
  transparency_exclusions: [],
  transparency_obfuscate_domains: []

config :ex_aws, http_client: Pleroma.HTTP.ExAws

config :web_push_encryption, http_client: Pleroma.HTTP.WebPush

config :pleroma, :instances_favicons, enabled: true
config :pleroma, :instances_nodeinfo, enabled: true

config :floki, :html_parser, Floki.HTMLParser.FastHtml

config :pleroma, Pleroma.Web.Auth.Authenticator, Pleroma.Web.Auth.PleromaAuthenticator

config :pleroma, Pleroma.User.Backup,
  purge_after_days: 30,
  limit_days: 7,
  dir: nil

config :pleroma, ConcurrentLimiter, [
  {Pleroma.Web.RichMedia.Helpers, [max_running: 5, max_waiting: 5]},
  {Pleroma.Web.ActivityPub.MRF.MediaProxyWarmingPolicy, [max_running: 5, max_waiting: 5]},
  {Pleroma.Search, [max_running: 30, max_waiting: 50]}
]

config :pleroma, Pleroma.Web.WebFinger, domain: nil, update_nickname_on_user_fetch: true

config :pleroma, Pleroma.Search, module: Pleroma.Search.DatabaseSearch

config :pleroma, Pleroma.Search.Meilisearch,
  url: "http://127.0.0.1:7700/",
  private_key: nil,
  initial_indexing_chunk_size: 100_000

config :pleroma, Pleroma.Search.Elasticsearch.Cluster,
  url: "http://localhost:9200",
  username: "elastic",
  password: "changeme",
  api: Elasticsearch.API.HTTP,
  json_library: Jason,
  indexes: %{
    activities: %{
      settings: "priv/es-mappings/activity.json",
      store: Pleroma.Search.Elasticsearch.Store,
      sources: [Pleroma.Activity],
      bulk_page_size: 1000,
      bulk_wait_interval: 15_000
    }
  }

config :pleroma, :translator,
  enabled: false,
  module: Pleroma.Akkoma.Translators.DeepL

config :pleroma, :deepl,
  # either :free or :pro
  tier: :free,
  api_key: ""

config :pleroma, :libre_translate,
  url: "http://127.0.0.1:5000",
  api_key: nil

config :pleroma, :argos_translate,
  command_argos_translate: "argos-translate",
  command_argospm: "argospm",
  strip_html: true

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
