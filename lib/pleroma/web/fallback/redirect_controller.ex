# Pleroma: A lightweight social networking server
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.Fallback.RedirectController do
  use Pleroma.Web, :controller

  require Logger

  alias Pleroma.User
  alias Pleroma.Web.Metadata
  alias Pleroma.Web.Preload

  def api_not_implemented(conn, _params) do
    conn
    |> put_status(404)
    |> json(%{error: "Not implemented"})
  end

  def redirector(conn, _params, code \\ 200) do
    conn
    |> put_resp_content_type("text/html")
    |> send_file(code, index_file_path(conn))
  end

  def redirector_with_meta(conn, %{"maybe_nickname_or_id" => maybe_nickname_or_id} = params) do
    with %User{} = user <- User.get_cached_by_nickname_or_id(maybe_nickname_or_id) do
      redirector_with_meta(conn, %{user: user})
    else
      nil ->
        redirector(conn, params)
    end
  end

  def redirector_with_meta(conn, params) do
    {:ok, index_content} = File.read(index_file_path(conn))

    if get_in(params, [:object]) do
      tags = build_tags(conn, params)
      preloads = preload_data(conn, params)
      title = "<title>#{Pleroma.Config.get([:instance, :name])}</title>"
      title2 = "<meta property=\"og:title\" content=\"#{params.user.name} の投稿\">"
      description = "<meta property=\"og:description\" content=\"#{params.object.data["content"]}\">"
      type = "<meta property=\"og:type\" content=\"article\" />"
      site_name = "<meta property=\"og:site_name\" content=\"flyerdonut\" />"
      image =
      case params.object.data["attachment"] do
        [] ->
          # attachmentが空のリストの場合の処理
          "<meta property=\"og:image\" content=#{List.first(params.user.avatar["url"])["href"]} />"
        _ ->
          # attachmentが空のリストでない場合の処理
          "<meta property=\"og:image\" content=#{List.first(List.first(params.object.data["attachment"])["url"])["href"]} /><meta name=\"note:card\" content=\"summary_large_image\">"
      end
      #datas = "<!-- datas #{inspect(params.object)} -->"
      twitter = "<meta name=\"twitter:card\" content=\"summary\" />"

      response =
        index_content
        |> String.replace("<!--server-generated-meta-->", tags <> preloads <> title <> title2 <> description <> type <> site_name <> image <> twitter)

      conn
      |> put_resp_content_type("text/html")
      |> send_resp(200, response)


    else
      #Objectが存在しない場合（Userページ）
      tags = build_tags(conn, params)
      preloads = preload_data(conn, params)
      title = "<title>#{Pleroma.Config.get([:instance, :name])}</title>"
      title2 = "<meta property=\"og:title\" content=\"#{params.user.name} のページ\">"
      description = "<meta property=\"og:description\" content=\"#{params.user.bio}\">"
      type = "<meta property=\"og:type\" content=\"article\" />"
      site_name = "<meta property=\"og:site_name\" content=\"flyerdonut\" />"
      image = "<meta property=\"og:image\" content=#{List.first(params.user.avatar["url"])["href"]} />"
      twitter = "<meta name=\"twitter:card\" content=\"summary\" />"

      response =
        index_content
        |> String.replace("<!--server-generated-meta-->", tags <> preloads <> title <> title2 <> description <> type <> site_name <> image <> twitter)

      conn
      |> put_resp_content_type("text/html")
      |> send_resp(200, response)
    end
  end

  def redirector_with_preload(conn, %{"path" => ["pleroma", "admin"]}) do
    redirect(conn, to: "/pleroma/admin/")
  end

  def redirector_with_preload(conn, params) do
    {:ok, index_content} = File.read(index_file_path(conn))
    preloads = preload_data(conn, params)
    tags = Metadata.build_static_tags(params)
    title = "<title>#{Pleroma.Config.get([:instance, :name])}</title>"

    response =
      index_content
      |> String.replace("<!--server-generated-meta-->", tags <> preloads <> title)

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, response)
  end

  def registration_page(conn, params) do
    redirector(conn, params)
  end

  def empty(conn, _params) do
    conn
    |> put_status(204)
    |> text("")
  end

  defp index_file_path(conn) do
    frontend_type = Pleroma.Web.Plugs.FrontendStatic.preferred_or_fallback(conn, :primary)
    Pleroma.Web.Plugs.InstanceStatic.file_path("index.html", frontend_type)
  end

  defp build_tags(conn, params) do
    try do
      Metadata.build_tags(params)
    rescue
      e ->
        Logger.error(
          "Metadata rendering for #{conn.request_path} failed.\n" <>
            Exception.format(:error, e, __STACKTRACE__)
        )

        ""
    end
  end

  defp preload_data(conn, params) do
    try do
      Preload.build_tags(conn, params)
    rescue
      e ->
        Logger.error(
          "Preloading for #{conn.request_path} failed.\n" <>
            Exception.format(:error, e, __STACKTRACE__)
        )

        ""
    end
  end
end
