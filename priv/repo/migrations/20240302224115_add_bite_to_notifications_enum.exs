defmodule Pleroma.Repo.Migrations.AddBiteToNotificationsEnum do
  use Ecto.Migration

  @disable_ddl_transaction true

  def up do
    """
    alter type notification_type add value if not exists 'bite'
    """
    |> execute()
  end

  def down do
    # Leave value in place
  end
end
