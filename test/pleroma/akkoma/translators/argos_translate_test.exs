defmodule Pleroma.Akkoma.Translators.ArgosTranslateTest do
  alias Pleroma.Akkoma.Translators.ArgosTranslate

  import Mock

  use Pleroma.DataCase, async: true

  setup do
    clear_config([:argos_translate, :command_argos_translate], "argos-translate_test")
    clear_config([:argos_translate, :command_argospm], "argospm_test")
  end

  test "it lists available languages" do
    languages =
      with_mock System, [:passthrough],
        cmd: fn "argospm_test", ["list"], _ ->
          {"translate-nl_en\ntranslate-en_nl\ntranslate-ja_en\n", 0}
        end do
        ArgosTranslate.languages()
      end

    assert {:ok, source_langs, dest_langs} = languages

    assert [%{code: "en", name: "en"}, %{code: "ja", name: "ja"}, %{code: "nl", name: "nl"}] =
             source_langs |> Enum.sort()

    assert [%{code: "en", name: "en"}, %{code: "nl", name: "nl"}] = dest_langs |> Enum.sort()
  end

  test "it translates from default language when no language is set" do
    translation_response =
      with_mock System, [:passthrough],
        cmd: fn "argos-translate_test", ["--from-lang", "en", "--to-lang", "fr", "blabla"], _ ->
          {"yadayada", 0}
        end do
        ArgosTranslate.translate("blabla", nil, "fr")
      end

    assert {:ok, "en", "yadayada"} = translation_response
  end

  test "it translates from the provided language" do
    translation_response =
      with_mock System, [:passthrough],
        cmd: fn "argos-translate_test", ["--from-lang", "nl", "--to-lang", "en", "blabla"], _ ->
          {"yadayada", 0}
        end do
        ArgosTranslate.translate("blabla", "nl", "en")
      end

    assert {:ok, "nl", "yadayada"} = translation_response
  end

  test "it returns a proper error when the executable can't be found" do
    non_existing_command = "sfqsfgqsefd"
    clear_config([:argos_translate, :command_argos_translate], non_existing_command)
    clear_config([:argos_translate, :command_argospm], non_existing_command)

    assert nil == System.find_executable(non_existing_command)

    assert {:error, "ArgosTranslate failed to fetch languages" <> _} = ArgosTranslate.languages()

    assert {:error, "ArgosTranslate failed to translate" <> _} =
             ArgosTranslate.translate("blabla", "nl", "en")
  end
end
