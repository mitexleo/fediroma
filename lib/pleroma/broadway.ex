defmodule Pleroma.Broadway do
  use Broadway
  alias Broadway.Message
  require Logger

  @queue "akkoma"
  @exchange "akkoma_exchange"
  @retry_header "x-retries"
  @delay_header "x-delay"

  def start_link(_args) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module:
          {BroadwayRabbitMQ.Producer,
           queue: @queue,
           after_connect: &declare_rabbitmq/1,
           metadata: [:routing_key, :headers],
           on_failure: :reject}
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

  defp declare_rabbitmq(amqp_channel) do
    declare_exchanges(amqp_channel)
    declare_queues(amqp_channel)
    declare_bindings(amqp_channel)
  end

  defp declare_exchanges(amqp_channel) do
    # Main exchange, all messages go here
    :ok =
      AMQP.Exchange.declare(amqp_channel, @exchange, :"x-delayed-message",
        durable: true,
        arguments: [{"x-delayed-type", :longstr, "topic"}]
      )
  end

  defp declare_queues(amqp_channel) do
    # Main queue, bound to main exchange
    {:ok, _} = AMQP.Queue.declare(amqp_channel, @queue, durable: true)
  end

  defp declare_bindings(amqp_channel) do
    :ok = AMQP.Queue.bind(amqp_channel, @queue, @exchange, routing_key: "#")
  end

  defp retry_count(:undefined), do: 0
  defp retry_count(headers) do
    match = Enum.find(headers, fn {k, _t, _v} -> k == @retry_header end)
    if is_nil(match) do
      0
    else
      elem(match, 2)
    end
  end

  @impl true
  def handle_message(_, %Message{data: data, metadata: %{routing_key: routing_key, headers: headers}} = message, _) do
    Logger.debug("Received message on #{routing_key}")
    with {:ok, data} <- Jason.decode(data),
         {module, data} <- Map.pop(data, "__module__"),
         module <- String.to_existing_atom(module),
         :ok <- perform_message(module, data) do
      message
    else
      err ->
        retries = retry_count(headers)
        if retries > 5 do
          Message.failed(message, err)
        else
          {:ok, _} = produce(routing_key, data, scheduled_in: 5000, retry_count: retries + 1)
          message
        end
    end
  end

  defp perform_message(module, args) do
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
    for message <- messages do
      %Message{data: data, metadata: %{routing_key: topic}, status: {:failed, reason}} = message
      {:ok, %{"op" => op}} = Jason.decode(data)
      Logger.error("Processing task on #{topic}(#{op}) failed: #{inspect(reason)}")
    end

    messages
  end

  def topics do
    Pleroma.Config.get([Oban, :queues])
    |> Keyword.keys()
  end

  def children do
    [Pleroma.Broadway]
  end

  defp add_headers([headers: headers] = opts, key, type, value) when is_list(headers) do
    Keyword.put(opts, :headers, [{key, type, value} | headers])
  end

  defp add_headers(opts, key, type, value) do
    Keyword.put(opts, :headers, [{key, type, value}])
  end

  defp maybe_with_priority(opts, params) do
    if !is_nil(params[:priority]) do
      Keyword.put(opts, :priority, params[:priority])
    else
      opts
    end
  end

  defp maybe_schedule_at(opts, params) do
    if !is_nil(params[:scheduled_at]) do
      time_in_ms = DateTime.diff(params[:scheduled_at], DateTime.utc_now())
      opts
      |> add_headers(@delay_header, :long, time_in_ms)
    else
      opts
    end
  end

  defp maybe_schedule_in(opts, params) do
    if !is_nil(params[:scheduled_in]) do
      opts
      |> add_headers(@delay_header, :long, params[:scheduled_in])
    else
      opts
    end
  end


  defp maybe_with_retry_count(opts, params) do
    if !is_nil(params[:retry_count]) do
      opts
      |> add_headers(@retry_header, :long, params[:retry_count])
    else
      opts
    end
  end

  def produce(topic, args, opts \\ []) do
    {:ok, connection} = AMQP.Connection.open()
    {:ok, channel} = AMQP.Channel.open(connection)

    publish_options =
      []
      |> maybe_with_priority(opts)
      |> maybe_schedule_at(opts)
      |> maybe_schedule_in(opts)
      |> maybe_with_retry_count(opts)

    Logger.debug("Sending to #{topic} with #{inspect(publish_options)}")
    :ok = AMQP.Basic.publish(channel, @exchange, topic, args, publish_options)
    :ok = AMQP.Connection.close(connection)
    {:ok, args}
  end
end
