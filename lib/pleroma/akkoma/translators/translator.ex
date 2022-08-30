defmodule Pleroma.Akkoma.Translator do
  @callback translate(String.t(), String.t()) :: {:ok, String.t(), String.t()} | {:error, any()}
  @callback languages() :: {:ok, [%{name: String.t(), code: String.t()}]} | {:error, any()}
end
