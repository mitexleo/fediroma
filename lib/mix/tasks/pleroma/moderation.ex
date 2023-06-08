defmodule Mix.Tasks.Pleroma.Moderation do
  use Mix.Task
  import Mix.Pleroma

  @shortdoc "Does moderation"

  def run(["rm-instance", domain | _rest]) do
    start_pleroma()
    IO.puts("Deleting #{domain}")
    Pleroma.Instances.Instance.perform(:delete_instance, domain)
    |> IO.inspect()
  end
end
