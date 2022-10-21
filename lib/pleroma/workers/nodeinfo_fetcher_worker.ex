defmodule Pleroma.Workers.NodeInfoFetcherWorker do
  use Oban.Worker, queue: :backup, max_attempts: 1

  alias Oban.Job
  alias Pleroma.Instance

  def process(domain) do
    %{"op" => "process", "domain" => domain}
    |> new()
    |> Oban.insert()
  end

  def perform(%Job{
        args: %{"op" => "process", "domain" => domain}
      }) do
    uri = URI.parse(domain)
    Instance.get_or_update_favicon(uri)
  end
end
