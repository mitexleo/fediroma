defmodule Pleroma.Akkoma.Translators.LibreTranslate do
  @behaviour Pleroma.Akkoma.Translator

  alias Pleroma.Config
  alias Pleroma.HTTP
  require Logger

  defp api_key do
    Config.get([:libre_translate, :api_key])
  end

  defp url do
    Config.get([:libre_translate, :url])
  end

  @impl Pleroma.Akkoma.Translator
  def languages do
    with {:ok, %{status: 200} = response} <- do_languages(),
         {:ok, body} <- Jason.decode(response.body) do
      resp = Enum.map(body, fn %{"code" => code, "name" => name} -> %{code: code, name: name} end)
      {:ok, resp}
    else
      {:ok, %{status: status} = response} ->
        Logger.warning("LibreTranslate: Request rejected: #{inspect(response)}")
        {:error, "LibreTranslate request failed (code #{status})"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl Pleroma.Akkoma.Translator
  def translate(string, to_language) do
    with {:ok, %{status: 200} = response} <- do_request(string, to_language),
         {:ok, body} <- Jason.decode(response.body) do
      %{"translatedText" => translated, "detectedLanguage" => %{"language" => detected}} = body

      {:ok, detected, translated}
    else
      {:ok, %{status: status} = response} ->
        Logger.warning("libre_translate: request failed, #{inspect(response)}")
        {:error, "libre_translate: request failed (code #{status})"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp do_request(string, to_language) do
    url = URI.parse(url())
    url = %{url | path: "/translate"}

    HTTP.post(
      to_string(url),
      Jason.encode!(%{
        q: string,
        source: "auto",
        target: to_language,
        format: "html",
        api_key: api_key()
      }),
      [
        {"content-type", "application/json"}
      ]
    )
  end

  defp do_languages() do
    url = URI.parse(url())
    url = %{url | path: "/languages"}

    HTTP.get(to_string(url))
  end
end
