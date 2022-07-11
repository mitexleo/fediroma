# Pleroma: A lightweight social networking server
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.ActivityPub.ObjectValidators.ArticleNotePageValidatorTest do
  use Pleroma.DataCase, async: true

  alias Pleroma.Web.ActivityPub.ObjectValidators.ArticleNotePageValidator
  alias Pleroma.Web.ActivityPub.Utils

  import Pleroma.Factory

  setup_all do
    Tesla.Mock.mock_global(fn env -> apply(HttpRequestMock, :request, [env]) end)

    :ok
  end

  describe "Notes" do
    setup do
      user = insert(:user)

      note = %{
        "id" => Utils.generate_activity_id(),
        "type" => "Note",
        "actor" => user.ap_id,
        "to" => [user.follower_address],
        "cc" => [],
        "content" => "Hellow this is content.",
        "context" => "xxx",
        "summary" => "a post"
      }

      %{user: user, note: note}
    end

    test "a basic note validates", %{note: note} do
      %{valid?: true} = ArticleNotePageValidator.cast_and_validate(note)
    end

    test "a note with a remote replies collection should validate", _ do
      insert(:user, %{ap_id: "https://bookwyrm.com/user/TestUser"})
      collection = File.read!("test/fixtures/bookwyrm-replies-collection.json")

      Tesla.Mock.mock(fn %{
                           method: :get,
                           url: "https://bookwyrm.com/user/TestUser/review/17/replies?page=1"
                         } ->
        %Tesla.Env{
          status: 200,
          body: collection,
          headers: HttpRequestMock.activitypub_object_headers()
        }
      end)

      note = Jason.decode!(File.read!("test/fixtures/bookwyrm-article.json"))

      %{valid?: true, changes: %{replies: ["https://bookwyrm.com/user/TestUser/status/18"]}} =
        ArticleNotePageValidator.cast_and_validate(note)
    end

    test "a note with an attachment should work", _ do
      insert(:user, %{ap_id: "https://owncast.localhost.localdomain/federation/user/streamer"})

      note =
        "test/fixtures/owncast-note-with-attachment.json"
        |> File.read!()
        |> Jason.decode!()

      %{valid?: true} = ArticleNotePageValidator.cast_and_validate(note)
    end

    test "a misskey MFM status with a content field should work and be linked", _ do
      local_user =
        insert(:user, %{nickname: "akkoma_user", ap_id: "http://localhost:4001/users/akkoma_user"})

      remote_user =
        insert(:user, %{
          nickname: "remote_user",
          ap_id: "http://misskey.local.live/users/remote_user"
        })

      insert(:user, %{ap_id: "https://misskey.local.live/users/92hzkskwgy"})

      note =
        "test/fixtures/misskey/mfm_x_format.json"
        |> File.read!()
        |> Jason.decode!()

      %{
        valid?: true,
        changes: %{
          content: content,
          source: %{
            "content" =>
              "@akkoma_user @remote_user @oops_not_a_mention linkifylink #dancedance $[jelly mfm goes here] \n\n## aaa",
            "mediaType" => "text/x.misskeymarkdown"
          }
        }
      } = ArticleNotePageValidator.cast_and_validate(note)

      assert content =~
               "<span class=\"h-card\"><a class=\"u-url mention\" data-user=\"#{local_user.id}\" href=\"#{local_user.ap_id}\" rel=\"ugc\">@<span>akkoma_user</span></a></span>"

      assert content =~
               "<span class=\"h-card\"><a class=\"u-url mention\" data-user=\"#{remote_user.id}\" href=\"#{remote_user.ap_id}\" rel=\"ugc\">@<span>remote_user</span></a></span>"

      assert content =~ "@oops_not_a_mention"
      assert content =~ "$[jelly mfm goes here] <br><br>## aaa"
    end

    test "a misskey MFM status with a _misskey_content field should work and be linked", _ do
      local_user =
        insert(:user, %{nickname: "akkoma_user", ap_id: "http://localhost:4001/users/akkoma_user"})

      insert(:user, %{ap_id: "https://misskey.local.live/users/92hzkskwgy"})

      note =
        "test/fixtures/misskey/mfm_underscore_format.json"
        |> File.read!()
        |> Jason.decode!()

      expected_content =
        "<span class=\"h-card\"><a class=\"u-url mention\" data-user=\"#{local_user.id}\" href=\"#{local_user.ap_id}\" rel=\"ugc\">@<span>akkoma_user</span></a></span> linkifylink <a class=\"hashtag\" data-tag=\"dancedance\" href=\"http://localhost:4001/tag/dancedance\" rel=\"tag ugc\">#dancedance</a> $[jelly mfm goes here] <br><br>## aaa"

      %{
        valid?: true,
        changes: %{
          content: ^expected_content,
          source: %{
            "content" => "@akkoma_user linkifylink #dancedance $[jelly mfm goes here] \n\n## aaa",
            "mediaType" => "text/x.misskeymarkdown"
          }
        }
      } = ArticleNotePageValidator.cast_and_validate(note)
    end
  end
end
