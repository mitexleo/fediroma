defmodule Pleroma.Object.PrunerTest do
  use Pleroma.DataCase, async: true

  alias Pleroma.Object
  alias Pleroma.Repo
  alias Pleroma.Object.Pruner

  import Pleroma.Factory

  describe "prune_deletes" do
    test "it prunes old delete objects" do
      new_tombstone = insert(:tombstone)

      old_tombstone =
        insert(:tombstone,
          inserted_at: DateTime.utc_now() |> DateTime.add(-31 * 24, :hour)
        )

      Pruner.prune_tombstones()
      assert Object.get_by_id(new_tombstone.id)
      refute Object.get_by_id(old_tombstone.id)
    end
  end
end
