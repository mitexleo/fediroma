# Pleroma: A lightweight social networking server
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.AdminAPI.ConfigControllerTest do
  use Pleroma.Web.ConnCase, async: false

  import Pleroma.Factory

  setup_all do
    Tesla.Mock.mock_global(fn env -> apply(HttpRequestMock, :request, [env]) end)

    :ok
  end

  setup do
    clear_config(:configurable_from_database, true)
    admin = insert(:user, is_admin: true)
    token = insert(:oauth_admin_token, user: admin)

    conn =
      build_conn()
      |> assign(:user, admin)
      |> assign(:token, token)
      |> put_req_header("content-type", "application/json")

    {:ok, %{admin: admin, token: token, conn: conn}}
  end

  describe "POST /api/v1/pleroma/admin/config" do
    test "Refuses to update non-whitelisted config options", %{conn: conn} do
      banned_config = %{
        configs: [
          %{
            group: ":mogrify",
            key: ":mogrify_command",
            value: [
              %{tuple: [":path", "sh"]},
              %{tuple: [":args", ["-c", "echo pwnd > /tmp/a"]]}
            ]
          }
        ]
      }

      clear_config([:database_config_whitelist], [{:pleroma}])

      resp_that_should_not_work =
        conn
        |> post(~p"/api/v1/pleroma/admin/config", banned_config)
        |> json_response_and_validate_schema(200)

      assert Enum.empty?(resp_that_should_not_work["configs"])

      clear_config([:database_config_whitelist], [{:mogrify}])

      resp_that_should_work =
        conn
        |> post(~p"/api/v1/pleroma/admin/config", banned_config)
        |> json_response_and_validate_schema(200)

      refute Enum.empty?(resp_that_should_work["configs"])
    end

    test "Refuses to update strictly disallowed options", %{conn: conn} do
      banned_config = %{
        configs: [
          %{
            group: ":pleroma",
            key: ":database_config_whitelist",
            value: [":pleroma"]
          },
          %{
            group: ":pleroma",
            key: ":argos_translate",
            value: [
              %{tuple: [":command_argospm", "/opt/oepsiewoepsie"]}
            ]
          },
          %{
            group: ":pleroma",
            key: "Pleroma.Web.MediaProxy.Invalidation.Script",
            value: "wowee"
          }
        ]
      }

      resp_that_should_not_work =
        conn
        |> post(~p"/api/v1/pleroma/admin/config", banned_config)
        |> json_response_and_validate_schema(200)

      assert Enum.empty?(resp_that_should_not_work["configs"])
    end
  end
end
