defmodule Pleroma.Web.MastodonFE.Controller do
  alias Pleroma.Config

  @local_mastodon_name "Mastodon-Local"
  @mastoFEEnabled Config.get([:frontends, :mastodon, "enabled"])

  def auth_controller_login do
    if @mastoFEEnabled do
      quote bind_quoted: [local_mastodon_name: @local_mastodon_name] do
        @doc "GET /web/login"
        # Local Mastodon FE login callback action
        def login(conn, %{"code" => auth_token} = params) do
          with {:ok, app} <- local_mastofe_app(),
               {:ok, auth} <- Pleroma.Web.OAuth.Authorization.get_by_token(app, auth_token),
               {:ok, oauth_token} <- Pleroma.Web.OAuth.Token.exchange_token(app, auth) do
            redirect_to =
              conn
              |> local_mastodon_post_login_path()
              |> Pleroma.Helpers.UriHelper.modify_uri_params(%{
                "access_token" => oauth_token.token
              })

            conn
            |> Pleroma.Helpers.AuthHelper.put_session_token(oauth_token.token)
            |> redirect(to: redirect_to)
          else
            _ -> redirect_to_oauth_form(conn, params)
          end
        end

        def login(conn, params) do
          with %{
                 assigns: %{
                   user: %Pleroma.User{},
                   token: %Pleroma.Web.OAuth.Token{app_id: app_id}
                 }
               } <- conn,
               {:ok, %{id: ^app_id}} <- local_mastofe_app() do
            redirect(conn, to: local_mastodon_post_login_path(conn))
          else
            _ -> redirect_to_oauth_form(conn, params)
          end
        end

        defp redirect_to_oauth_form(conn, _params) do
          with {:ok, app} <- local_mastofe_app() do
            path =
              Pleroma.Web.Router.Helpers.o_auth_path(conn, :authorize,
                response_type: "code",
                client_id: app.client_id,
                redirect_uri: ".",
                scope: Enum.join(app.scopes, " ")
              )

            redirect(conn, to: path)
          end
        end

        @spec local_mastofe_app() :: {:ok, App.t()} | {:error, Ecto.Changeset.t()}
        def local_mastofe_app do
          Pleroma.Web.OAuth.App.get_or_make(
            %{client_name: unquote(local_mastodon_name), redirect_uris: "."},
            ["read", "write", "follow", "push", "admin"]
          )
        end
      end
    end
  end

  def auth_controller_local_functions do
    if @mastoFEEnabled do
      quote do
        defp local_mastodon_post_login_path(conn) do
          case get_session(conn, :return_to) do
            nil ->
              Pleroma.Web.Router.Helpers.masto_fe_path(conn, :index, ["getting-started"])

            return_to ->
              delete_session(conn, :return_to)
              return_to
          end
        end
      end
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
