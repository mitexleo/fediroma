defmodule Pleroma.Web.AkkomaAPI.ProtocolHandlerControllerTest do
  use Pleroma.Web.ConnCase
  use Oban.Testing, repo: Pleroma.Repo

  alias Pleroma.Activity

  import Pleroma.Factory

  describe "GET /.well-known/protocol-handler" do
    test "should return bad_request when missing `target`" do
      %{conn: conn} = oauth_access([])

      resp =
        conn
        |> get("/.well-known/protocol-handler")
        |> json_response(400)

      assert resp =~ "Missing `target` parameter"
    end

    test "should return redirect when target parameter is present" do
      %{conn: conn} = oauth_access([])

      resp =
        conn
        |> get("/.well-known/protocol-handler?target=web+ap://outerheaven.club/objects/337fca0c-6282-4142-9491-df51ac917504")
        |> html_response(302)

      assert resp =~ "You are being"
    end
  end

  describe "GET /api/v1/akkoma/protocol-handler" do
    setup do
      clear_config([Pleroma.Web.Endpoint, :url, :host], "sub.example.com")
      Tesla.Mock.mock(fn
        %{method: :get, url: "https://mastodon.social/users/emelie/statuses/101849165031453009"} ->
          %Tesla.Env{
            status: 200,
            headers: [{"content-type", "application/activity+json"}],
            body: File.read!("test/fixtures/tesla_mock/status.emelie.json")
          }
        %{method: :get, url: "https://mastodon.social/users/emelie"} ->
          %Tesla.Env{
            status: 200,
            headers: [{"content-type", "application/activity+json"}],
            body: File.read!("test/fixtures/tesla_mock/emelie.json")
          }
        %{method: :get, url: "https://mastodon.social/@emelie"} ->
          %Tesla.Env{
            status: 200,
            headers: [{"content-type", "application/activity+json"}],
            body: File.read!("test/fixtures/tesla_mock/emelie.json")
          }
        %{method: :get, url: "https://mastodon.social/users/emelie/collections/featured"} ->
          %Tesla.Env{
            status: 200,
            headers: [{"content-type", "application/activity+json"}],
            body:
              File.read!("test/fixtures/users_mock/masto_featured.json")
              |> String.replace("{{domain}}", "mastodon.social")
              |> String.replace("{{nickname}}", "emelie")
          }
        _ -> %Tesla.Env{
          status: 404,
        }
      end)
    end

    test "should return bad_request when target prefix has unknown protocol" do
      %{conn: conn} = oauth_access([])

      resp =
        conn
        |> get("/api/v1/akkoma/protocol-handler?target=web%2Bfoo%3A%2F%2Fouterheaven.club/objects/337fca0c-6282-4142-9491-df51ac917504")
        |> json_response(400)

      assert resp =~ "Could not handle protocol URL"
    end

    test "should return forbidden for unauthed user when target is remote" do
      %{conn: conn} = oauth_access([])

      resp =
        conn
        |> get("/api/v1/akkoma/protocol-handler?target=web%2Bap%3A%2F%2Fouterheaven.club/objects/337fca0c-6282-4142-9491-df51ac917504")
        |> json_response(403)

      assert resp =~ "Invalid credentials."
    end

    test "should return redirect for unauthed user when target is local AP ID for user" do
      %{conn: conn} = oauth_access([])
      local_user = insert(:user, %{nickname: "akkoma@sub.example.com", local: true, ap_id: "https://sub.example.com/users/akkoma"})

      resp =
        conn
        |> get("/api/v1/akkoma/protocol-handler?target=web%2Bap%3A%2F%2Fsub.example.com/users/akkoma")
        |> html_response(302)

      assert resp =~ "You are being"
      assert resp =~ "<a href=\"/users/#{local_user.id}\">"
    end

    test "should return not_found for unauthed user when target is local AP ID for DM note activity" do
      %{conn: conn} = oauth_access([])
      local_user = insert(:user, %{nickname: "akkoma@sub.example.com", local: true, ap_id: "https://sub.example.com/users/akkoma"})
      note = insert(:note, %{
        id: "AYAsX3ZRH6NJAzZmEa",
        data: %{
          "cc" => [],
          "to" => [],
          "actor" => local_user.ap_id,
          "id" => "https://sub.example.com/notice/AYAsX3ZRH6NJAzZmEa",
          "summary" => "",
          "content" => "Pleroma's really cool!",
          "directMessage" => true,
        }
      })
      insert(:note_activity, note: note, user: local_user)

      conn
        |> get("/api/v1/akkoma/protocol-handler?target=web%2Bap%3A%2F%2Fsub.example.com/notice/AYAsX3ZRH6NJAzZmEa")
        |> json_response(404)
    end

    test "should return not_found for unauthed user when target is local AP ID for public note activity" do
      %{conn: conn} = oauth_access([])
      local_user = insert(:user, %{nickname: "akkoma@sub.example.com", local: true, ap_id: "https://sub.example.com/users/akkoma"})
      note = insert(:note, %{
        id: "AYAsX3ZRH6NJAzZmPa",
        data: %{
          "cc" => [],
          "to" => ["https://www.w3.org/ns/activitystreams#Public"],
          "actor" => local_user.ap_id,
          "id" => "https://sub.example.com/notice/AYAsX3ZRH6NJAzZmPa",
          "summary" => "",
          "content" => "Pleroma's really cool!",
        }
      })
      activity = insert(:note_activity, note: note, user: local_user, visibility: "direct")

      resp =
        conn
        |> get("/api/v1/akkoma/protocol-handler?target=web%2Bap%3A%2F%2Fsub.example.com/notice/AYAsX3ZRH6NJAzZmPa")
        |> html_response(302)

        assert resp =~ "You are being"
        assert resp =~ "<a href=\"/notice/#{activity.id}\">"
    end

    test "should return redirect for authed user when target is AP ID for remote user" do
      %{conn: conn} = oauth_access(["read:search"])
      remote_user = insert(:user, %{nickname: "akkoma@ihatebeinga.live", local: false, ap_id: "https://ihatebeinga.live/users/akkoma"})

      resp =
        conn
        |> get("/api/v1/akkoma/protocol-handler?target=web%2Bap%3A%2F%2Fihatebeinga.live/users/akkoma")
        |> html_response(302)

      assert resp =~ "You are being"
      assert resp =~ "<a href=\"/users/#{remote_user.id}\">"
    end

    test "should return redirect for authed user when target is URI for remote user" do
      %{conn: conn} = oauth_access(["read:search"])
      remote_user = insert(:user, %{
        nickname: "emelie@mastodon.social",
        local: false,
        ap_id: "https://mastodon.social/users/emelie",
        uri: "https://mastodon.social/@emelie",
      })

      resp =
        conn
        |> get("/api/v1/akkoma/protocol-handler?target=web%2Bap%3A%2F%2Fmastodon.social/%40emelie")
        |> html_response(302)

      assert resp =~ "You are being"
      assert resp =~ "<a href=\"/users/#{remote_user.id}\">"
    end

    test "should return redirect for authed user when target is AP ID for user, stripping userinfo" do
      %{conn: conn} = oauth_access(["read:search"])
      remote_user = insert(:user, %{nickname: "akkoma@ihatebeinga.live", local: false, ap_id: "https://ihatebeinga.live/users/akkoma"})

      resp =
        conn
        |> get("/api/v1/akkoma/protocol-handler?target=web%2Bap%3A%2F%2Fusername%3Apassword%40ihatebeinga.live/users/akkoma")
        |> html_response(302)

      assert resp =~ "You are being"
      assert resp =~ "<a href=\"/users/#{remote_user.id}\">"
    end

    test "should return redirect for authed user when target is AP ID for remote note activity" do
      %{conn: conn} = oauth_access(["read:search"])

      resp =
        conn
        |> get("/api/v1/akkoma/protocol-handler?target=web%2Bap%3A%2F%2Fmastodon.social/users/emelie/statuses/101849165031453009")
        |> html_response(302)

      assert activity = Activity.get_by_object_ap_id_with_object("https://mastodon.social/users/emelie/statuses/101849165031453009")
      assert resp =~ "You are being"
      assert resp =~ "<a href=\"/notice/#{activity.id}\">"
    end
  end
end
