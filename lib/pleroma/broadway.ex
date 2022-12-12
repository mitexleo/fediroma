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
             auto_delete: false
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

  def produce(topic, args) do
    IO.puts("Producing message on #{topic}: #{inspect(args)}")
    {:ok, connection} = AMQP.Connection.open()
    {:ok, channel} = AMQP.Channel.open(connection)
    AMQP.Basic.publish(channel, "", @queue, args)
    AMQP.Connection.close(connection)
  end
end
