defmodule Pleroma.Repo.Migrations.DeleteDeliveriesOnObjectDelete do
  use Ecto.Migration
  def up do
    drop constraint(:deliveries, "deliveries_object_id_fkey")
    alter table(:deliveries) do
        modify :object_id, references(:objects, type: :id, on_delete: :delete_all), null: false
    end
  end

  def down do
    drop constraint(:deliveries, "deliveries_object_id_fkey")
    alter table(:deliveries) do
        modify :object_id, references(:objects, type: :id), null: false
    end
  end
end
