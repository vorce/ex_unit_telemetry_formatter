defmodule ExUnitTelemetryFormatter.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_unit_telemetry_formatter,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:telemetry, "~> 1.0"}
    ]
  end
end
