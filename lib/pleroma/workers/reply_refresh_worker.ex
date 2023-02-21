defmodule Pleroma.Workers.ReplyRefresherWorker do
  @moduledoc """
  The worker to pull new replies to discovered posts.
  """

  use Pleroma.Workers.WorkerHelper, queue: "reply_refresher"

  alias Pleroma.Object
  alias Pleroma.Object.Fetcher
  alias Pleroma.Workers.ReplyRefresherWorker

  @backoff_time {60, 600, 3600, 6 * 3600, 24 * 3600, 3 * 24 * 3600}

  @impl Oban.Worker
  def perform(%Job{args: %{"object_id" => object_id, "run_count" => run_count}}) do
    case process_object(object_id) do
      {:ok, true} -> reschedule(object_id, 0)
      {:ok, false} -> reschedule(object_id, run_count + 1)
      e -> e
    end
  end

  def schedule(id) do
    %{object_id: id, run_count: 0}
    |> ReplyRefresherWorker.new(schedule_in: elem(@backoff_time, 0))
    |> Oban.insert()
  end

  defp reschedule(id, run_count) when run_count < tuple_size(@backoff_time) do
    %{object_id: id, run_count: run_count}
    |> ReplyRefresherWorker.new(schedule_in: elem(@backoff_time, run_count))
    |> Oban.insert()
    {:ok, nil}
  end

  defp reschedule(_, _) do
    {:ok, nil}
  end

  defp reply_to_id(id) when is_binary(id) do
    id
  end
  defp reply_to_id(%{"id" => id}) do
    id
  end
  defp process_reply(reply) do
    id = reply_to_id(reply)
    with {_, nil} <- {:find, Object.get_by_ap_id(id)},
         {_, {:ok, _}} <- {:fetch, Fetcher.fetch_object_from_id(id)} do
      {:ok, true}
    else
      {:find, _obj} -> {:ok, false}
      {:fetch, err} -> {:ok, err}
    end
  end
  defp process_object(id) do
    obj = Object.get_by_ap_id(id)
    with {:ok, new_obj} <- Fetcher.refetch_object(obj),
         {:ok, replies} <- fetch_reply_list(new_obj.data["replies"]) do
         Enum.reduce_while(Enum.map(replies, &process_reply/1), {:ok, false}, fn x, acc ->
	   case x do
	     {:ok, false} -> {:cont, acc}
	     {:ok, true} -> {:cont, {:ok, true}}
	     e -> {:halt, e}
	   end
	 end)
    end
  end
  defp fetch_reply_list(replies) when is_list(replies) do
    {:ok, replies}
  end
  defp fetch_reply_list(%{"type" => type} = replies)
      when type in ["Collection", "OrderedCollection", "CollectionPage", "OrderedCollectionPage"] do
    Akkoma.Collections.Fetcher.fetch_collection(replies)
  end
end
