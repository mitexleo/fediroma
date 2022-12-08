defmodule Pleroma.Akkoma.Translators.ArgosTranslate do
  @behaviour Pleroma.Akkoma.Translator

  alias Pleroma.Config

  defp argos_translate do
    Config.get([:argos_translate, :command_argos_translate])
  end

  defp argospm do
    Config.get([:argos_translate, :command_argospm])
  end

  defp default_language do
    Config.get([:argos_translate, :default_language])
  end

  defp safe_languages() do
    try do
      System.cmd(argospm(), ["list"], stderr_to_stdout: true, parallelism: true)
    rescue
      _ -> {"Command #{argospm()} not found", 1}
    end
  end

  @impl Pleroma.Akkoma.Translator
  def languages do
    with {response, 0} <- safe_languages() do
      langs =
        response
        |> String.split("\n", trim: true)
        |> Enum.map(fn
          "translate-" <> l -> String.split(l, "_")
          _ -> ""
        end)

      source_langs =
        langs
        |> Enum.map(fn [l, _] -> %{code: l, name: l} end)
        |> Enum.uniq()

      dest_langs =
        langs
        |> Enum.map(fn [_, l] -> %{code: l, name: l} end)
        |> Enum.uniq()

      {:ok, source_langs, dest_langs}
    else
      {response, _} -> {:error, "ArgosTranslate failed to fetch languages (#{response})"}
    end
  end

  defp safe_translate(string, from_language, to_language) do
    try do
      System.cmd(
        argos_translate(),
        ["--from-lang", from_language, "--to-lang", to_language, string],
        stderr_to_stdout: true,
        parallelism: true
      )
    rescue
      _ -> {"Command #{argos_translate()} not found", 1}
    end
  end

  @impl Pleroma.Akkoma.Translator
  def translate(string, from_language, to_language) do
    # Akkoma's Pleroma-fe expects us to detect the source language automatically.
    # Argos-translate doesn't have that option (yet?)
    #     see <https://github.com/argosopentech/argos-translate/issues/9>
    # For now we choose a default source language from settings.
    # Afterwards people get the option to overwrite the source language from a dropdown.
    from_language = from_language || default_language()
    to_language = to_language || default_language()

    with {translated, 0} <-
           safe_translate(string, from_language, to_language) do
      {:ok, from_language, translated}
    else
      {response, _} -> {:error, "ArgosTranslate failed to translate (#{response})"}
    end
  end
end
