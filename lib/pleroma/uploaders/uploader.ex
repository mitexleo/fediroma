# Pleroma: A lightweight social networking server
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Uploaders.Uploader do
  import Pleroma.Web.Gettext

  @mix_env Mix.env()

  @moduledoc """
  Defines the contract to put and get an uploaded file to any backend.
  """

  @doc """
  Instructs how to get the file from the backend.

  Used by `Pleroma.Web.Plugs.UploadedMedia`.
  """
  @type get_method :: {:static_dir, directory :: String.t()} | {:url, url :: String.t()}
  @callback get_file(file :: String.t()) :: {:ok, get_method()}

  @doc """
  Put a file to the backend.

  Returns:

  * `:ok` which assumes `{:ok, upload.path}`
  * `{:ok, spec}` where spec is:
    * `{:file, filename :: String.t}` to handle reads with `get_file/1` (recommended)

    This allows to correctly proxy or redirect requests to the backend, while allowing to migrate backends without breaking any URL.
  * `{url, url :: String.t}` to bypass `get_file/2` and use the `url` directly in the activity.
  * `{:error, String.t}` error information if the file failed to be saved to the backend.
  * `:wait_callback` will wait for an http post request at `/api/pleroma/upload_callback/:upload_path` and call the uploader's `http_callback/3` method.

  """
  @callback put_file(upload :: struct()) ::
              :ok | {:ok, Pleroma.Upload.t()} | {:error, String.t()} | :wait_callback

  @callback delete_file(file :: String.t()) :: :ok | {:error, String.t()}

  @callback base_url() :: String.t()

  @callback http_callback(Plug.Conn.t(), Map.t(), Pleroma.Upload.t()) ::
              {:ok, Plug.Conn.t(), Pleroma.Upload.t()}
              | {:error, Plug.Conn.t(), String.t()}
  @optional_callbacks http_callback: 3

  @spec put_file(module(), upload :: struct()) :: {:ok, Pleroma.Upload.t()} | {:error, String.t()}
  def put_file(uploader, upload) do
    case uploader.put_file(upload) do
      {:ok, %Pleroma.Upload{}} = ok -> ok
      :wait_callback -> handle_callback(uploader, upload)
      {:error, _} = error -> error
    end
  end

  defp handle_callback(uploader, upload) do
    :global.register_name({__MODULE__, upload.path}, self())

    receive do
      {__MODULE__, pid, conn, params} ->
        case uploader.http_callback(conn, params, upload) do
          {:ok, conn, upload} ->
            send(pid, {__MODULE__, conn})
            {:ok, upload}

          {:error, conn, error} ->
            send(pid, {__MODULE__, conn})
            {:error, error}
        end
    after
      callback_timeout() -> {:error, dgettext("errors", "Uploader callback timeout")}
    end
  end

  defp callback_timeout do
    case @mix_env do
      :test -> 1_000
      _ -> 30_000
    end
  end
end
