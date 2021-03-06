defmodule Carrier.Mixfile do
  use Mix.Project

  def project do
    [app: :carrier,
     version: "0.2.0",
     elixir: "~> 1.2",
     elixirc_paths: elixirc_paths(Mix.env),
     elixirc_options: [warnings_as_errors: System.get_env("ALLOW_WARNINGS") == nil],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger,
                    :emqttc]]
  end

  defp deps do
    [{:enacl, github: "jlouis/enacl", tag: "0.15.0"},
     {:emqttc, github: "operable/emqttc", tag: "cog-0.2"},
     {:adz, git: "git@github.com:operable/adz", tag: "0.2"},
     {:uuid, "~> 1.1.3"},
     {:poison, "~> 1.5.2"}]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]
end
