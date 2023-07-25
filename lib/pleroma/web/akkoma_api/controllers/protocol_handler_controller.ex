# Pleroma: A lightweight social networking server
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.AkkomaAPI.ProtocolHandlerController do
  use Pleroma.Web, :controller

  import Pleroma.Web.ControllerHelper, only: [json_response: 3]

  alias Pleroma.Activity
  alias Pleroma.Search.DatabaseSearch
  alias Pleroma.User
  alias Pleroma.Web.Plugs.OAuthScopesPlug

  @oauth_search_actions [:handle]

  # Note: (requires read:search)
  plug(OAuthScopesPlug, %{scopes: ["read:search"], fallback: :proceed_unauthenticated} when action in @oauth_search_actions)

  # Protocol definition: https://datatracker.ietf.org/doc/draft-soni-protocol-handler-well-known-uri/
  def reroute(conn, %{"target" => target_param}) do
    conn |> redirect(to: "/api/v1/akkoma/protocol-handler?#{URI.encode_query([target: target_param])}")
  end
  def reroute(conn, _), do: conn |> json_response(:bad_request, "Missing `target` parameter")

  def handle(%{assigns: %{user: user}} = conn, %{"target" => "web+ap://" <> identifier}) when is_nil(user) do
    # Unauthenticated, only local records should be searched
    cond do
      String.starts_with?(identifier, Pleroma.Config.get([Pleroma.Web.Endpoint, :url, :host])) -> find_and_redirect(conn, identifier)
      true -> conn |> json_response(:forbidden, "Invalid credentials.")
    end
  end

  def handle(%{assigns: %{user: user}} = conn, %{"target" => "web+ap://" <> identifier}) when not is_nil(user) do
    # Authenticated User
    find_and_redirect(conn, identifier)
  end

  def handle(conn, _), do: conn |> json_response(:bad_request, "Could not handle protocol URL")

  # Should webfinger handles even be accepted? They are not ActivityPub URLs
  defp find_and_redirect(conn, "@" <> identifier) do
    with {:error, _err} <- User.get_or_fetch(identifier) do
      conn |> json_response(:not_found, "Not Found - @#{identifier}")
    else
      {:ok, %User{} = found_user} -> conn |> redirect(to: "/users/#{found_user.id}")
    end
  end

  defp find_and_redirect(%{assigns: %{user: user}} = conn, identifier) do
    with {:error, _err} <- User.get_or_fetch("https://" <> identifier),
        [] <- DatabaseSearch.maybe_fetch([], user, "https://" <> identifier) do
      conn |> json_response(:not_found, "Not Found - #{identifier}")
    else
      {:ok, %User{} = found_user} -> conn |> redirect(to: "/users/#{found_user.id}")

      [%Activity{} = found_activity] -> conn |> redirect(to: "/notice/#{found_activity.id}")
    end
  end
end
