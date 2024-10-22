# Pleroma: A lightweight social networking server
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.HTTP do
  @moduledoc """
    Wrapper for `Tesla.request/2`.
  """

  alias Pleroma.HTTP.AdapterHelper
  alias Pleroma.HTTP.Request
  alias Pleroma.HTTP.RequestBuilder, as: Builder
  alias Tesla.Client
  alias Tesla.Env

  require Logger

  @type t :: __MODULE__
  @type method() :: :get | :post | :put | :delete | :head

  @doc """
  Performs GET request.

  See `Pleroma.HTTP.request/5`
  """
  @spec get(Request.url() | nil, Request.headers(), keyword()) ::
          nil | {:ok, Env.t()} | {:error, any()}
  def get(url, headers \\ [], options \\ [])
  def get(nil, _, _), do: nil
  def get(url, headers, options), do: request(:get, url, nil, headers, options)

  @spec head(Request.url(), Request.headers(), keyword()) :: {:ok, Env.t()} | {:error, any()}
  def head(url, headers \\ [], options \\ []), do: request(:head, url, nil, headers, options)

  @doc """
  Performs POST request.

  See `Pleroma.HTTP.request/5`
  """
  @spec post(Request.url(), String.t(), Request.headers(), keyword()) ::
          {:ok, Env.t()} | {:error, any()}
  def post(url, body, headers \\ [], options \\ []),
    do: request(:post, url, body, headers, options)

  @doc """
  Builds and performs http request.

  # Arguments:
  `method` - :get, :post, :put, :delete, :head
  `url` - full url
  `body` - request body
  `headers` - a keyworld list of headers, e.g. `[{"content-type", "text/plain"}]`
  `options` - custom, per-request middleware or adapter options

  # Returns:
  `{:ok, %Tesla.Env{}}` or `{:error, error}`

  """
  @spec request(method(), Request.url(), String.t(), Request.headers(), keyword()) ::
          {:ok, Env.t()} | {:error, any()}
  def request(method, url, body, headers, options) when is_binary(url) do
    uri = URI.parse(url)
    adapter_opts = AdapterHelper.options(uri, options || [])

    adapter_opts =
      if uri.scheme == :https do
        AdapterHelper.maybe_add_cacerts(adapter_opts, :public_key.cacerts_get())
      else
        adapter_opts
      end

    options = put_in(options[:adapter], adapter_opts)
    params = options[:params] || []
    request = build_request(method, headers, options, url, body, params)
    client = Tesla.client([Tesla.Middleware.FollowRedirects, Tesla.Middleware.Telemetry])

    Logger.debug("Outbound: #{method} #{url}")
    request(client, request)
  rescue
    e ->
      Logger.error("Failed to fetch #{url}: #{inspect(e)}")
      {:error, :fetch_error}
  end

  @spec request(Client.t(), keyword()) :: {:ok, Env.t()} | {:error, any()}
  def request(client, request), do: Tesla.request(client, request)

  defp build_request(method, headers, options, url, body, params) do
    Builder.new()
    |> Builder.method(method)
    |> Builder.headers(headers)
    |> Builder.opts(options)
    |> Builder.url(url)
    |> Builder.add_param(:body, :body, body)
    |> Builder.add_param(:query, :query, params)
    |> Builder.convert_to_keyword()
  end
end
