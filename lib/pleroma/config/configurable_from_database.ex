defmodule Pleroma.Config.ConfigurableFromDatabase do
  alias Pleroma.Config

  # Basically it's silly to let this be configurable
  # set a list of things that we can set in the database
  # this is mostly our stuff, with some extra in there
  @allowed_groups [
    {:logger},
    {:pleroma, Pleroma.Captcha},
    {:pleroma, Pleroma.Captcha.Kocaptcha},
    {:pleroma, Pleroma.Upload},
    {:pleroma, Pleroma.Uploaders.Local},
    {:pleroma, Pleroma.Uploaders.S3},
    {:pleroma, :auth},
    {:pleroma, :emoji},
    {:pleroma, :http},
    {:pleroma, :instance},
    {:pleroma, :welcome},
    {:pleroma, :feed},
    {:pleroma, :markup},
    {:pleroma, :frontend_configurations},
    {:pleroma, :assets},
    {:pleroma, :manifest},
    {:pleroma, :activitypub},
    {:pleroma, :streamer},
    {:pleroma, :user},
    {:pleroma, :mrf_normalize_markup},
    {:pleroma, :mrf_rejectnonpublic},
    {:pleroma, :mrf_hellthread},
    {:pleroma, :mrf_simple},
    {:pleroma, :mrf_keyword},
    {:pleroma, :mrf_hashtag},
    {:pleroma, :mrf_subchain},
    {:pleroma, :mrf_activity_expiration},
    {:pleroma, :mrf_vocabulary},
    {:pleroma, :mrf_inline_quote},
    {:pleroma, :mrf_object_age},
    {:pleroma, :mrf_follow_bot},
    {:pleroma, :mrf_reject_newly_created_account_notes},
    {:pleroma, :rich_media},
    {:pleroma, :media_proxy},
    {:pleroma, Pleroma.Web.MediaProxy.Invalidation.Http},
    {:pleroma, :media_preview_proxy},
    {:pleroma, Pleroma.Web.Metadata},
    {:pleroma, Pleroma.Web.Metadata.Providers.Theme},
    {:pleroma, Pleroma.Web.Preload},
    {:pleroma, :http_security},
    {:pleroma, Pleroma.User},
    {:pleroma, Oban},
    {:pleroma, :workers},
    {:pleroma, Pleroma.Formatter},
    {:pleroma, Pleroma.Emails.Mailer},
    {:pleroma, Pleroma.Emails.UserEmail},
    {:pleroma, Pleroma.Emails.NewUsersDigestEmail},
    {:pleroma, Pleroma.ScheduledActivity},
    {:pleroma, :email_notifications},
    {:pleroma, :oauth2},
    {:pleroma, Pleroma.Web.Plugs.RemoteIp},
    {:pleroma, :static_fe},
    {:pleroma, :frontends},
    {:pleroma, :web_cache_ttl},
    {:pleroma, :majic_pool},
    {:pleroma, :restrict_unauthenticated},
    {:pleroma, Pleroma.Web.ApiSpec.CastAndValidate},
    {:pleroma, :mrf},
    {:pleroma, :instances_favicons},
    {:pleroma, :instances_nodeinfo},
    {:pleroma, Pleroma.User.Backup},
    {:pleroma, ConcurrentLimiter},
    {:pleroma, Pleroma.Web.WebFinger},
    {:pleroma, Pleroma.Search},
    {:pleroma, Pleroma.Search.Meilisearch},
    {:pleroma, Pleroma.Search.Elasticsearch.Cluster},
    {:pleroma, :translator},
    {:pleroma, :deepl},
    {:pleroma, :libre_translate},
    # But not argostranslate, because executables!
    {:pleroma, Pleroma.Upload.Filter.AnonymizeFilename},
    {:pleroma, Pleroma.Upload.Filter.Mogrify},
    {:pleroma, Pleroma.Workers.PurgeExpiredActivity},
    {:pleroma, :rate_limit}
  ]

  def allowed_groups, do: @allowed_groups

  def enabled, do: Config.get(:configurable_from_database)

  # the whitelist check can be called from either the loader or the
  # doc generator, which is spitting out strings
  defp maybe_stringified_atom_equal(a, b) do
    a == inspect(b) || a == b
  end

  def whitelisted_config?(group, key) do
    allowed_groups()
    |> Enum.any?(fn
      {whitelisted_group} ->
        maybe_stringified_atom_equal(group, whitelisted_group)

      {whitelisted_group, whitelisted_key} ->
        maybe_stringified_atom_equal(group, whitelisted_group) && maybe_stringified_atom_equal(key, whitelisted_key)
    end)
  end

  def whitelisted_config?(%{group: group, key: key}) do
    whitelisted_config?(group, key)
  end

  def whitelisted_config?(%{group: group} = config) do
    whitelisted_config?(group, config[:key])
  end
end
