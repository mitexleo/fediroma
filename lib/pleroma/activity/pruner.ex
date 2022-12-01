defmodule Pleroma.Activity.Pruner do
  @moduledoc """
  Prunes activities from the database.
  """
  @cutoff 30

  alias Pleroma.Activity
  alias Pleroma.Repo
  import Ecto.Query

  def prune_deletes do
    before_time = cutoff()

    from(a in Activity,
      where: fragment("?->>'type' = ?", a.data, "Delete") and a.inserted_at < ^before_time
    )
    |> Repo.delete_all(timeout: :infinity)
  end

  defp cutoff do
    DateTime.utc_now() |> Timex.shift(days: -@cutoff)
  end
end
