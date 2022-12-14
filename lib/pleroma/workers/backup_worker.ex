# Pleroma: A lightweight social networking server
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Workers.BackupWorker do
  use Pleroma.Workers.WorkerHelper, queue: "backup", max_attempts: 1
  alias Oban.Job
  alias Pleroma.User.Backup

  @impl Oban.Worker
  def timeout(_job) do
    Pleroma.Config.get([:workers, :timeout, :backup], :timer.minutes(1))
  end

  @spec schedule_deletion(Backup.t()) ::
          {:error, any} | {:ok, Oban.Job.t()}
  def schedule_deletion(backup) do
    days = Pleroma.Config.get([Backup, :purge_after_days])
    time = 60 * 60 * 24 * days
    scheduled_at = Calendar.NaiveDateTime.add!(backup.inserted_at, time)

    enqueue("delete", %{"backup_id" => backup.id}, scheduled_at: scheduled_at)
  end

  def delete(backup) do
    enqueue("delete", %{"backup_id" => backup.id})
  end

  @impl true
  def perform(%Job{
        args: %{"op" => "process", "backup_id" => backup_id, "admin_user_id" => admin_user_id}
      }) do
    with {:ok, %Backup{} = backup} <-
           backup_id |> Backup.get() |> Backup.process(),
         {:ok, _job} <- schedule_deletion(backup),
         :ok <- Backup.remove_outdated(backup),
         :ok <- maybe_deliver_email(backup, admin_user_id) do
      {:ok, backup}
    end
  end

  def perform(%Job{args: %{"op" => "delete", "backup_id" => backup_id}}) do
    case Backup.get(backup_id) do
      %Backup{} = backup -> Backup.delete(backup)
      nil -> :ok
    end
  end

  defp has_email?(user) do
    not is_nil(user.email) and user.email != ""
  end

  defp maybe_deliver_email(backup, admin_user_id) do
    has_mailer = Pleroma.Config.get([Pleroma.Emails.Mailer, :enabled])
    backup = backup |> Pleroma.Repo.preload(:user)

    if has_email?(backup.user) and has_mailer do
      backup
      |> Pleroma.Emails.UserEmail.backup_is_ready_email(admin_user_id)
      |> Pleroma.Emails.Mailer.deliver()

      :ok
    else
      :ok
    end
  end
end
