# Pleroma: A lightweight social networking server
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mix.Tasks.Pleroma.Queue do
  use Mix.Task

  import Mix.Pleroma

  def run(["queues"]) do
    start_pleroma()

    Pleroma.Config.get([Oban, :queues])
    |> Keyword.keys()
    |> Enum.join("\n")
    |> shell_info()
  end
end
