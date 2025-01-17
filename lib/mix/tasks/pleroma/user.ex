# Pleroma: A lightweight social networking server
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mix.Tasks.Pleroma.User do
  use Mix.Task
  import Mix.Pleroma
  alias Ecto.Changeset
  alias Pleroma.User
  alias Pleroma.Web.ActivityPub.ActivityPub
  alias Pleroma.UserInviteToken
  alias Pleroma.Web.ActivityPub.Builder
  alias Pleroma.Web.ActivityPub.Pipeline
  use Pleroma.Web, :verified_routes

  @shortdoc "Manages Pleroma users"
  @moduledoc File.read!("docs/docs/administration/CLI_tasks/user.md")

  def run(["new", nickname, email | rest]) do
    {options, [], []} =
      OptionParser.parse(
        rest,
        strict: [
          name: :string,
          bio: :string,
          password: :string,
          moderator: :boolean,
          admin: :boolean,
          assume_yes: :boolean
        ],
        aliases: [
          y: :assume_yes
        ]
      )

    name = Keyword.get(options, :name, nickname)
    bio = Keyword.get(options, :bio, "")

    {password, generated_password?} =
      case Keyword.get(options, :password) do
        nil ->
          {:crypto.strong_rand_bytes(16) |> Base.encode64(), true}

        password ->
          {password, false}
      end

    moderator? = Keyword.get(options, :moderator, false)
    admin? = Keyword.get(options, :admin, false)
    assume_yes? = Keyword.get(options, :assume_yes, false)

    shell_info("""
    A user will be created with the following information:
      - nickname: #{nickname}
      - email: #{email}
      - password: #{if(generated_password?, do: "[generated; a reset link will be created]", else: password)}
      - name: #{name}
      - bio: #{bio}
      - moderator: #{if(moderator?, do: "true", else: "false")}
      - admin: #{if(admin?, do: "true", else: "false")}
    """)

    proceed? = assume_yes? or shell_prompt("Continue?", "n") in ~w(Yn Y y)

    if proceed? do
      start_pleroma()

      params = %{
        nickname: nickname,
        email: email,
        password: password,
        password_confirmation: password,
        name: name,
        bio: bio
      }

      changeset = User.register_changeset(%User{}, params, is_confirmed: true)
      {:ok, _user} = User.register(changeset)

      shell_info("User #{nickname} created")

      if moderator? do
        run(["set", nickname, "--moderator"])
      end

      if admin? do
        run(["set", nickname, "--admin"])
      end

      if generated_password? do
        run(["reset_password", nickname])
      end
    else
      shell_info("User will not be created.")
    end
  end

  def run(["rm", nickname]) do
    start_pleroma()

    with %User{local: true} = user <- User.get_cached_by_nickname(nickname),
         {:ok, delete_data, _} <- Builder.delete(user, user.ap_id),
         {:ok, _delete, _} <- Pipeline.common_pipeline(delete_data, local: true) do
      shell_info("User #{nickname} deleted.")
    else
      _ -> shell_error("No local user #{nickname}")
    end
  end

  def run(["reset_password", nickname]) do
    start_pleroma()

    with %User{local: true} = user <- User.get_cached_by_nickname(nickname),
         {:ok, token} <- Pleroma.PasswordResetToken.create_token(user) do
      shell_info("Generated password reset token for #{user.nickname}")

      shell_info("URL: #{~p[/api/v1/pleroma/password_reset/#{token.token}]}")
    else
      _ ->
        shell_error("No local user #{nickname}")
    end
  end

  def run(["reset_mfa", nickname]) do
    start_pleroma()

    with %User{local: true} = user <- User.get_cached_by_nickname(nickname),
         {:ok, _token} <- Pleroma.MFA.disable(user) do
      shell_info("Multi-Factor Authentication disabled for #{user.nickname}")
    else
      _ ->
        shell_error("No local user #{nickname}")
    end
  end

  def run(["activate", nickname]) do
    start_pleroma()

    with %User{} = user <- User.get_cached_by_nickname(nickname),
         false <- user.is_active do
      User.set_activation(user, true)
      :timer.sleep(500)

      shell_info("Successfully activated #{nickname}")
    else
      true ->
        shell_info("User #{nickname} already activated")

      _ ->
        shell_error("No user #{nickname}")
    end
  end

  def run(["deactivate", nickname]) do
    start_pleroma()

    with %User{} = user <- User.get_cached_by_nickname(nickname),
         true <- user.is_active do
      User.set_activation(user, false)
      :timer.sleep(500)

      user = User.get_cached_by_id(user.id)

      if Enum.empty?(Enum.filter(User.get_friends(user), & &1.local)) do
        shell_info("Successfully deactivated #{nickname} and unsubscribed all local followers")
      end
    else
      false ->
        shell_info("User #{nickname} already deactivated")

      _ ->
        shell_error("No user #{nickname}")
    end
  end

  def run(["deactivate_all_from_instance", instance]) do
    start_pleroma()

    Pleroma.User.Query.build(%{nickname: "@#{instance}"})
    |> Pleroma.Repo.chunk_stream(500, :batches)
    |> Stream.each(fn users ->
      users
      |> Enum.each(fn user ->
        run(["deactivate", user.nickname])
      end)
    end)
    |> Stream.run()
  end

  def run(["set", nickname | rest]) do
    start_pleroma()

    {options, [], []} =
      OptionParser.parse(
        rest,
        strict: [
          admin: :boolean,
          confirmed: :boolean,
          locked: :boolean,
          moderator: :boolean
        ]
      )

    with %User{local: true} = user <- User.get_cached_by_nickname(nickname) do
      user =
        case Keyword.get(options, :admin) do
          nil -> user
          value -> set_admin(user, value)
        end

      user =
        case Keyword.get(options, :confirmed) do
          nil -> user
          value -> set_confirmation(user, value)
        end

      user =
        case Keyword.get(options, :locked) do
          nil -> user
          value -> set_locked(user, value)
        end

      _user =
        case Keyword.get(options, :moderator) do
          nil -> user
          value -> set_moderator(user, value)
        end
    else
      _ ->
        shell_error("No local user #{nickname}")
    end
  end

  def run(["tag", nickname | tags]) do
    start_pleroma()

    with %User{} = user <- User.get_cached_by_nickname(nickname) do
      user = user |> User.tag(tags)

      shell_info("Tags of #{user.nickname}: #{inspect(user.tags)}")
    else
      _ ->
        shell_error("Could not change user tags for #{nickname}")
    end
  end

  def run(["untag", nickname | tags]) do
    start_pleroma()

    with %User{} = user <- User.get_cached_by_nickname(nickname) do
      user = user |> User.untag(tags)

      shell_info("Tags of #{user.nickname}: #{inspect(user.tags)}")
    else
      _ ->
        shell_error("Could not change user tags for #{nickname}")
    end
  end

  def run(["refetch_public_keys"]) do
    start_pleroma()

    Pleroma.User.Query.build(%{
      external: true,
      is_active: true
    })
    |> refetch_public_keys()
  end

  def run(["refetch_public_keys" | rest]) do
    start_pleroma()

    Pleroma.User.Query.build(%{
      ap_id: rest
    })
    |> refetch_public_keys()
  end

  def run(["invite" | rest]) do
    {options, [], []} =
      OptionParser.parse(rest,
        strict: [
          expires_at: :string,
          max_use: :integer
        ]
      )

    options =
      options
      |> Keyword.update(:expires_at, {:ok, nil}, fn
        nil -> {:ok, nil}
        val -> Date.from_iso8601(val)
      end)
      |> Enum.into(%{})

    start_pleroma()

    with {:ok, val} <- options[:expires_at],
         options = Map.put(options, :expires_at, val),
         {:ok, invite} <- UserInviteToken.create_invite(options) do
      shell_info("Generated user invite token " <> String.replace(invite.invite_type, "_", " "))

      url = url(~p[/registration/#{invite.token}])
      shell_info(url)
    else
      error ->
        shell_error("Could not create invite token: #{inspect(error)}")
    end
  end

  def run(["invites"]) do
    start_pleroma()

    shell_info("Invites list:")

    UserInviteToken.list_invites()
    |> Enum.each(fn invite ->
      expire_info =
        with expires_at when not is_nil(expires_at) <- invite.expires_at do
          " | Expires at: #{Date.to_string(expires_at)}"
        end

      using_info =
        with max_use when not is_nil(max_use) <- invite.max_use do
          " | Max use: #{max_use}    Left use: #{max_use - invite.uses}"
        end

      shell_info(
        "ID: #{invite.id} | Token: #{invite.token} | Token type: #{invite.invite_type} | Used: #{invite.used}#{expire_info}#{using_info}"
      )
    end)
  end

  def run(["revoke_invite", token]) do
    start_pleroma()

    with {:ok, invite} <- UserInviteToken.find_by_token(token),
         {:ok, _} <- UserInviteToken.update_invite(invite, %{used: true}) do
      shell_info("Invite for token #{token} was revoked.")
    else
      _ -> shell_error("No invite found with token #{token}")
    end
  end

  def run(["delete_activities", nickname]) do
    start_pleroma()

    with %User{local: true} = user <- User.get_cached_by_nickname(nickname) do
      User.delete_user_activities(user)
      shell_info("User #{nickname} statuses deleted.")
    else
      _ ->
        shell_error("No local user #{nickname}")
    end
  end

  def run(["change_email", nickname, email]) do
    start_pleroma()

    with %User{} = user <- User.get_cached_by_nickname(nickname) do
      user
      |> User.update_changeset(%{"email" => email})
      |> User.update_and_set_cache()

      shell_info("#{nickname}'s email updated")
    end
  end

  def run(["show", nickname]) do
    start_pleroma()

    user =
      nickname
      |> User.get_cached_by_nickname()

    shell_info(user)
  end

  def run(["send_confirmation", nickname]) do
    start_pleroma()

    with %User{} = user <- User.get_cached_by_nickname(nickname) do
      user
      |> Pleroma.Emails.UserEmail.account_confirmation_email()
      |> Pleroma.Emails.Mailer.deliver!()

      shell_info("#{nickname}'s email sent")
    end
  end

  def run(["confirm", nickname]) do
    start_pleroma()

    with %User{} = user <- User.get_cached_by_nickname(nickname) do
      {:ok, user} = User.confirm(user)

      message = if !user.is_confirmed, do: "needs", else: "doesn't need"

      shell_info("#{nickname} #{message} confirmation.")
    else
      _ ->
        shell_error("No local user #{nickname}")
    end
  end

  def run(["confirm_all"]) do
    start_pleroma()

    Pleroma.User.Query.build(%{
      local: true,
      is_active: true,
      is_moderator: false,
      is_admin: false,
      invisible: false
    })
    |> Pleroma.Repo.chunk_stream(500, :batches)
    |> Stream.each(fn users ->
      users
      |> Enum.each(fn user -> User.set_confirmation(user, true) end)
    end)
    |> Stream.run()
  end

  def run(["unconfirm_all"]) do
    start_pleroma()

    Pleroma.User.Query.build(%{
      local: true,
      is_active: true,
      is_moderator: false,
      is_admin: false,
      invisible: false
    })
    |> Pleroma.Repo.chunk_stream(500, :batches)
    |> Stream.each(fn users ->
      users
      |> Enum.each(fn user -> User.set_confirmation(user, false) end)
    end)
    |> Stream.run()
  end

  def run(["sign_out", nickname]) do
    start_pleroma()

    with %User{local: true} = user <- User.get_cached_by_nickname(nickname) do
      User.global_sign_out(user)

      shell_info("#{nickname} signed out from all apps.")
    else
      _ ->
        shell_error("No local user #{nickname}")
    end
  end

  def run(["blocking", nickname]) do
    start_pleroma()

    with %User{local: true} = user <- User.get_cached_by_nickname(nickname) do
      blocks = User.following_ap_ids(user)
      shell_info(blocks)
    end
  end

  def run(["timeline_query", nickname]) do
    start_pleroma()

    params = %{local: true}

    with %User{local: true} = user <- User.get_cached_by_nickname(nickname) do
      followed_hashtags =
        user
        |> User.followed_hashtags()
        |> Enum.map(& &1.id)

      params =
        params
        |> Map.put(:type, ["Create", "Announce"])
        |> Map.put(:limit, 20)
        |> Map.put(:blocking_user, user)
        |> Map.put(:muting_user, user)
        |> Map.put(:reply_filtering_user, user)
        |> Map.put(:announce_filtering_user, user)
        |> Map.put(:user, user)
        |> Map.put(:local_only, params[:local])
        |> Map.put(:hashtags, followed_hashtags)
        |> Map.delete(:local)

      _activities =
        [user.ap_id | User.following(user)]
        |> ActivityPub.fetch_activities(params)
    end
  end

  def run(["list"]) do
    start_pleroma()

    Pleroma.User.Query.build(%{local: true})
    |> Pleroma.Repo.chunk_stream(500, :batches)
    |> Stream.each(fn users ->
      users
      |> Enum.each(fn user ->
        shell_info(
          "#{user.nickname} moderator: #{user.is_moderator}, admin: #{user.is_admin}, locked: #{user.is_locked}, is_active: #{user.is_active}"
        )
      end)
    end)
    |> Stream.run()
  end

  def run(["fix_follow_state", local_user, remote_user]) do
    start_pleroma()

    with {:local, %User{} = local} <- {:local, User.get_by_nickname(local_user)},
         {:remote, %User{} = remote} <- {:remote, User.get_by_nickname(remote_user)},
         {:follow_data, %{data: %{"state" => request_state}}} <-
           {:follow_data, Pleroma.Web.ActivityPub.Utils.fetch_latest_follow(local, remote)} do
      calculated_state = User.following?(local, remote)

      shell_info(
        "Request state is #{request_state}, vs calculated state of following=#{calculated_state}"
      )

      if calculated_state == false && request_state == "accept" do
        shell_info("Discrepancy found, fixing")
        Pleroma.Web.CommonAPI.reject_follow_request(local, remote)
        shell_info("Relationship fixed")
      else
        shell_info("No discrepancy found")
      end
    else
      {:local, _} ->
        shell_error("No local user #{local_user}")

      {:remote, _} ->
        shell_error("No remote user #{remote_user}")

      {:follow_data, _} ->
        shell_error("No follow data for #{local_user} and #{remote_user}")
    end
  end

  def run(["convert_id", id]) do
    {:ok, uuid} = FlakeId.Ecto.Type.dump(id)
    {:ok, raw_id} = Ecto.UUID.load(uuid)
    shell_info(raw_id)
  end

  defp refetch_public_keys(query) do
    query
    |> Pleroma.Repo.chunk_stream(50, :batches)
    |> Stream.each(fn users ->
      users
      |> Enum.each(fn user ->
        shell_info("Re-Resolving: #{user.ap_id}")

        with {:ok, user} <- Pleroma.User.fetch_by_ap_id(user.ap_id),
             changeset <- Pleroma.User.update_changeset(user),
             {:ok, _user} <- Pleroma.User.update_and_set_cache(changeset) do
          :ok
        else
          error -> shell_info("Could not resolve: #{user.ap_id}, #{inspect(error)}")
        end
      end)
    end)
    |> Stream.run()
  end

  defp set_moderator(user, value) do
    {:ok, user} =
      user
      |> Changeset.change(%{is_moderator: value})
      |> User.update_and_set_cache()

    shell_info("Moderator status of #{user.nickname}: #{user.is_moderator}")
    user
  end

  defp set_admin(user, value) do
    {:ok, user} = User.admin_api_update(user, %{is_admin: value})

    shell_info("Admin status of #{user.nickname}: #{user.is_admin}")
    user
  end

  defp set_locked(user, value) do
    {:ok, user} =
      user
      |> Changeset.change(%{is_locked: value})
      |> User.update_and_set_cache()

    shell_info("Locked status of #{user.nickname}: #{user.is_locked}")
    user
  end

  defp set_confirmation(user, value) do
    {:ok, user} = User.set_confirmation(user, value)

    shell_info("Confirmation status of #{user.nickname}: #{user.is_confirmed}")
    user
  end
end
