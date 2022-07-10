defmodule Pleroma.Web.Plugs.SubdomainStatic do
  require Pleroma.Constants
  alias Pleroma.Web.Plugs.FrontendStatic

  @moduledoc """
  This is a shim to call `Plug.Static` but with runtime `from` configuration`. It dispatches to the different frontends.
  """
  @behaviour Plug

  defdelegate file_path(path, frontend_type), to: FrontendStatic

  def init(opts) do
    opts
    |> Keyword.put(:from, "__unconfigured_frontend_static_plug")
    |> Plug.Static.init()
    |> Map.put(:frontend_type, opts[:frontend_type])
    |> Map.put(:subdomain, opts[:subdomain])
  end

  def call(conn, opts) do
    subdomain =
      conn.host
      |> String.split(".")
      |> List.first()

    with false <- FrontendStatic.api_route?(conn.path_info),
         false <- FrontendStatic.invalid_path?(conn.path_info),
         true <- subdomain == opts[:subdomain],
         frontend_type <- Map.get(opts, :frontend_type, opts[:subdomain]),
         path when not is_nil(path) <- file_path("", frontend_type) do
      call_static(conn, opts, path)
    else
      _ ->
        conn
    end
  end

  defp call_static(conn, opts, from) do
    opts = Map.put(opts, :from, from)
    Plug.Static.call(conn, opts)
  end

  defmacro generate_plug(config) do
    quote do
      plug(Pleroma.Web.Plugs.SubdomainStatic,
        at: "/",
        frontend_type: unquote(config)["key"],
        subdomain: unquote(config)["subdomain"],
        gzip: true,
        cache_control_for_etags: @static_cache_control,
        headers: %{
          "cache-control" => @static_cache_control
        }
      )
    end
  end
end
