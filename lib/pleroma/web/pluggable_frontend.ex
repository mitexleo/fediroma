defmodule Pleroma.Web.PluggableFrontend do
  alias Pleroma.Config

  def routers do
    conf =
      [:frontends, :enabled]
      |> Config.get()

    unless is_nil(conf) do
      conf
      |> Keyword.to_list()
      |> Enum.map(&router/1)
    end
  end

  def plugs do
    conf =
      [:frontends, :extra]
      |> Config.get()

    unless is_nil(conf) do
      conf
      |> Keyword.to_list()
      |> Enum.map(&plug/1)
    end
  end

  defp router({name, config}) do
    unless is_nil(Map.get(config, "router")) do
      forwarder({name, config})
    end
  end

  defp plug({name, config}) do
    if is_nil(Map.get(config, "router")) do
      forwarder({name, config})
    end
  end

  defp forwarder({frontend, %{"url_prefix" => prefixes} = config}) when is_list(prefixes) do
    prefixes
    |> Enum.map(fn prefix -> forwarder({frontend, Map.put(config, "url_prefix", prefix)}) end)
  end

  defp forwarder({_frontend, %{"url_prefix" => prefix, "router" => router}}) do
    quote bind_quoted: [prefix: prefix, router: router] do
      match(:*, prefix, router, :any)
    end
  end

  defp forwarder({frontend, %{"url_prefix" => prefix}}) do
    quote bind_quoted: [prefix: prefix, frontend: frontend] do
      plug(Pleroma.Web.Plugs.FrontendStatic,
        at: prefix,
        frontend_type: frontend,
        gzip: true,
        cache_control_for_etags: @static_cache_control,
        headers: %{
          "cache-control" => @static_cache_control
        }
      )
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
