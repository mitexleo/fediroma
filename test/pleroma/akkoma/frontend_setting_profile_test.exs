defmodule Pleroma.Akkoma.FrontendSettingProfileTest do
  use Pleroma.DataCase, async: true
  use Oban.Testing, repo: Pleroma.Repo
  alias Pleroma.Akkoma.FrontendSettingProfile

  import Pleroma.Factory

  describe "changeset/2" do
    test "valid" do
      user = insert(:user)
      frontend_name = "test"
      profile_name = "test"
      settings = %{"test" => "test"}
      struct = %FrontendSettingProfile{}

      attrs = %{
        user_id: user.id,
        frontend_name: frontend_name,
        profile_name: profile_name,
        settings: settings
      }

      assert %{valid?: true} = FrontendSettingProfile.changeset(struct, attrs)
    end

    test "when settings is too long" do
      clear_config([:instance, :max_frontend_settings_json_chars], 10)
      user = insert(:user)
      frontend_name = "test"
      profile_name = "test"
      settings = %{"verylong" => "verylongoops"}
      struct = %FrontendSettingProfile{}

      attrs = %{
        user_id: user.id,
        frontend_name: frontend_name,
        profile_name: profile_name,
        settings: settings
      }

      assert %{valid?: false, errors: [settings: {"is too long", _}]} =
               FrontendSettingProfile.changeset(struct, attrs)
    end

    test "when frontend name is too short" do
      user = insert(:user)
      frontend_name = ""
      profile_name = "test"
      settings = %{"test" => "test"}
      struct = %FrontendSettingProfile{}

      attrs = %{
        user_id: user.id,
        frontend_name: frontend_name,
        profile_name: profile_name,
        settings: settings
      }

      assert %{valid?: false, errors: [frontend_name: {"can't be blank", _}]} =
               FrontendSettingProfile.changeset(struct, attrs)
    end

    test "when profile name is too short" do
      user = insert(:user)
      frontend_name = "test"
      profile_name = ""
      settings = %{"test" => "test"}
      struct = %FrontendSettingProfile{}

      attrs = %{
        user_id: user.id,
        frontend_name: frontend_name,
        profile_name: profile_name,
        settings: settings
      }

      assert %{valid?: false, errors: [profile_name: {"can't be blank", _}]} =
               FrontendSettingProfile.changeset(struct, attrs)
    end
  end

  describe "create_or_update/2" do
    test "it should create a new record" do
      user = insert(:user)
      frontend_name = "test"
      profile_name = "test"
      settings = %{"test" => "test"}

      assert {:ok, %FrontendSettingProfile{}} =
               FrontendSettingProfile.create_or_update(user, frontend_name, profile_name, settings)
    end

    test "it should update a record" do
      user = insert(:user)
      frontend_name = "test"
      profile_name = "test"

      insert(:frontend_setting_profile,
        user: user,
        frontend_name: frontend_name,
        profile_name: profile_name,
        settings: %{"test" => "test"}
      )

      settings = %{"test" => "test2"}

      assert {:ok, %FrontendSettingProfile{settings: ^settings}} =
               FrontendSettingProfile.create_or_update(user, frontend_name, profile_name, settings)
    end
  end
end
