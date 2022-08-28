defmodule Akkoma.Translators.DeepL do
  @behaviour Akkoma.Translator

  use Tesla
  alias Pleroma.Config

  plug(Tesla.Middleware.EncodeFormUrlencoded)
  plug(Tesla.Middleware.DecodeJson)

  defp base_url(:free) do
    "https://api-free.deepl.com/v2/"
  end

  defp base_url(:pro) do
    "https://api.deepl.com/v2/"
  end

  defp api_key do
    Config.get([:deepl, :api_key])
  end

  defp tier do
    Config.get([:deepl, :tier])
  end

  @impl Akkoma.Translator
  def translate(string, to_language) do
    with {:ok, response} <- do_request(api_key(), tier(), string, to_language) do
      %{"translations" => [%{"text" => translated, "detected_source_language" => detected}]} =
        response.body

      {:ok, detected, translated}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp do_request(api_key, tier, string, to_language) do
    post(base_url(tier) <> "translate", %{
      auth_key: api_key,
      text: string,
      target_lang: to_language
    })
  end
end
