# Pleroma: A lightweight social networking server
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.MastodonAPI.AuthController do
  use Pleroma.Web, :controller

  import Pleroma.Web.ControllerHelper, only: [json_response: 3]

  alias Pleroma.Helpers.AuthHelper
  alias Pleroma.Web.OAuth.Token
  alias Pleroma.Web.OAuth.Token.Strategy.Revoke, as: RevokeToken
  alias Pleroma.Web.TwitterAPI.TwitterAPI
  alias Pleroma.Web.MastodonFE.Controller, as: MastodonFEController

  action_fallback(Pleroma.Web.MastodonAPI.FallbackController)

  plug(Pleroma.Web.Plugs.RateLimiter, [name: :password_reset] when action == :password_reset)

  use MastodonFEController, :auth_controller_login

  @doc "DELETE /auth/sign_out"
  def logout(conn, _) do
    conn =
      with %{assigns: %{token: %Token{} = oauth_token}} <- conn,
           session_token = AuthHelper.get_session_token(conn),
           {:ok, %Token{token: ^session_token}} <- RevokeToken.revoke(oauth_token) do
        AuthHelper.delete_session_token(conn)
      else
        _ -> conn
      end

    redirect(conn, to: "/")
  end

  @doc "POST /auth/password"
  def password_reset(conn, params) do
    nickname_or_email = params["email"] || params["nickname"]

    TwitterAPI.password_reset(nickname_or_email)

    json_response(conn, :no_content, "")
  end

  use MastodonFEController, :auth_controller_local_functions
end
