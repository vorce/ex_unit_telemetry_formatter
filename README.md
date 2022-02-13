![CI](https://github.com/vorce/ex_unit_telemetry_formatter/actions/workflows/action.yml/badge.svg)

# ExUnit Telemetry Formatter

An [ExUnit formatter](https://hexdocs.pm/ex_unit/1.13/ExUnit.Formatter.html) that emits [telemetry](https://hexdocs.pm/telemetry/readme.html) events about your test suite.

## Use cases

- Enable reporting of test suite metrics to external systems

## Events

See [`lib/ex_unit_telemetry_formatter.ex`](lib/ex_unit_telemetry_formatter.ex) documentation.

## Installation

Not on Hex yet! I want to test the formatter in some projects first.

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `test_stats` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_unit_telemetry_formatter, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/test_stats](https://hexdocs.pm/test_stats).
