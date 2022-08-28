defmodule Akkoma.Translators.LibreTranslate do
  @behaviour Akkoma.Translator

  use Tesla
  alias Pleroma.Config

  plug(Tesla.Middleware.JSON)

  defp api_key do
    Config.get([:libre_translate, :api_key])
  end

  defp url do
    Config.get([:libre_translate, :url])
  end

  @impl Akkoma.Translator
  def translate(string, to_language) do
    with {:ok, response} <- do_request(string, to_language) do
      %{"translatedText" => translated, "detectedLanguage" => %{"language" => detected}} = response.body
      {:ok, detected, translated}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp do_request(string, to_language) do
    url = URI.parse(url())
    url = %{url | path: "/translate"}

    post(url, %{
      q: string,
      source: "auto",
      target: to_language,
      api_key: api_key()
    })
  end
end
