defmodule Pleroma.Repo.Migrations.AddNodeinfo do
  use Ecto.Migration

  def up do
    alter table(:instances) do
      add_if_not_exists(:nodeinfo, :map, default: %{})
    end
  end

  def down do
    alter table(:instances) do
      remove_if_exists(:nodeinfo, :map)
    end
  end
end
