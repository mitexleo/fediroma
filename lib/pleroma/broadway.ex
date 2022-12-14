defmodule Pleroma.Broadway do
  use Broadway
  alias Broadway.Message
  require Logger

  @queue "akkoma"

  def start_link(_args) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module:
          {BroadwayRabbitMQ.Producer,
           queue: @queue,
           declare: [
             durable: true,
             auto_delete: false,
             exclusive: true,
             arguments: [
              {"x-delayed-type", "direct"}
             ]
           ],
            on_failure: :reject_and_requeue
        }
      ],
      processors: [
        default: [
          concurrency: 10
        ]
      ],
      batchers: [
        default: [
          batch_size: 10,
          batch_timeout: 100,
          concurrency: 10
        ]
      ]
    )
  end

  @impl true
  def handle_message(_, %Message{data: data} = message, _) do
    with {:ok, data} <- Jason.decode(data),
         {module, data} <- Map.pop(data, "__module__"),
         module <- String.to_existing_atom(module),
         :ok <- perform_message(module, data) do
      Logger.debug("Received message: #{inspect(data)}")
      message
    else
      err ->
        IO.inspect(err)
        Message.failed(message, err)
    end
  end

  defp perform_message(module, args) do
    IO.inspect(args)
    case module.perform(%Oban.Job{args: args}) do
      :ok ->
        :ok

      {:ok, _} ->
        :ok

      err ->
        err
    end
  end

  @impl true
  def handle_batch(_, batch, _, _) do
    batch
  end

  @impl true
  def handle_failed(messages, _) do
    Logger.error("Failed messages: #{inspect(messages)}")
    messages
  end

  def topics do
    Pleroma.Config.get([Oban, :queues])
    |> Keyword.keys()
  end

  def children do
    [Pleroma.Broadway]
  end

  defp maybe_add_headers([headers: headers] = opts, key, value) when is_list(headers) do
    Keyword.put(opts, :headers, [{key, value} | headers])
  end
  defp maybe_add_headers(opts, key, value) do
    Keyword.put(opts, :headers, [{key, value}])
  end

  defp maybe_with_priority(opts, [priority: priority]) when is_integer(priority) do
    Keyword.put(opts, :priority, priority)
  end
  defp maybe_with_priority(opts, _), do: opts

  defp maybe_with_delay(opts, [scheduled_at: scheduled_at]) do
    time_in_ms = DateTime.diff(DateTime.utc_now(), scheduled_at)
    opts
    |> maybe_add_headers("x-delay", to_string(time_in_ms))
  end
  defp maybe_with_delay(opts, _), do: opts

  def produce(topic, args, opts \\ []) do
    IO.puts("Producing message on #{topic}: #{inspect(args)}")
    {:ok, connection} = AMQP.Connection.open()
    {:ok, channel} = AMQP.Channel.open(connection)
    publish_options =
        []
        |> maybe_with_priority(opts)
        |> maybe_with_delay(opts)

    AMQP.Basic.publish(channel, "", @queue, args, publish_options)
    AMQP.Connection.close(connection)
  end
end
