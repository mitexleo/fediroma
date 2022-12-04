defmodule Pleroma.User.HashtagFollow do
  use Ecto.Schema
  import Ecto.Changeset

  alias Pleroma.User
  alias Pleroma.Hashtag
  alias Pleroma.Repo

  schema "user_follows_hashtag" do
    belongs_to(:user, User, type: FlakeId.Ecto.CompatType)
    belongs_to(:hashtag, Hashtag)
  end

  def changeset(%__MODULE__{} = user_hashtag_follow, attrs) do
    user_hashtag_follow
    |> cast(attrs, [:user_id, :hashtag_id])
    |> unique_constraint(:hashtag_id,
      name: :user_hashtag_follows_user_id_hashtag_id_index,
      message: "already following"
    )
    |> validate_required([:user_id, :hashtag_id])
  end

  def new(%User{} = user, %Hashtag{} = hashtag) do
    %__MODULE__{}
    |> changeset(%{user_id: user.id, hashtag_id: hashtag.id})
    |> Repo.insert(on_conflict: :nothing)
  end
end
