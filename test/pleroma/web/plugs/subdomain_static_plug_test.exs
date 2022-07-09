# Pleroma: A lightweight social networking server
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.Plugs.SubdomainStaticPlugTest do
  use Pleroma.Web.ConnCase

  @dir "test/tmp/instance_static"

  setup do
    File.mkdir_p!(@dir)
    on_exit(fn -> File.rm_rf(@dir) end)
  end

  setup do: clear_config([:instance, :static_dir], @dir)

  test "init will give a static plug config + the frontend type" do
    opts =
      [
        at: "/",
        frontend_type: :subdomain
      ]
      |> Pleroma.Web.Plugs.FrontendStatic.init()

    assert opts[:at] == []
    assert opts[:frontend_type] == :subdomain
  end

  test "overrides existing static files when the request is on the subdomain", %{conn: conn} do
    clear_config([:frontends, :extra], [
        %{"subdomain" => "edge", "key" => :edge}
    ])
    clear_config([:frontends, :edge], 
        %{"name" => "edge", "ref" => "maximum"}
    )
    name = "edge"
    ref = "maximum"

    path = "#{@dir}/frontends/#{name}/#{ref}"

    File.mkdir_p!(path)
    File.write!("#{path}/index.html", "from subdomain plug")

    index = get(conn, "/")
    assert html_response(index, 200) =~ "Welcome to Akkoma"

    subdomain_conn = Map.put(conn, :host, "edge.example.com")
    index = get(subdomain_conn, "/")
    assert html_response(index, 200) == "from subdomain plug"
  end

  test "api routes are detected correctly" do
    # If this test fails we have probably added something
    # new that should be in /api/ instead
    expected_routes = [
      "api",
      "main",
      "ostatus_subscribe",
      "oauth",
      "objects",
      "activities",
      "notice",
      "@:nickname",
      ":nickname",
      "users",
      "tags",
      "mailer",
      "inbox",
      "relay",
      "internal",
      ".well-known",
      "nodeinfo",
      "manifest.json",
      "web",
      "auth",
      "embed",
      "proxy",
      "phoenix",
      "test",
      "user_exists",
      "check_password"
    ]

    assert expected_routes == Pleroma.Web.Router.get_api_routes()
  end
end
