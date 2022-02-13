defmodule ExUnitTelemetryFormatterTest do
  use ExUnit.Case, async: false
  doctest ExUnitTelemetryFormatter

  defmacrop defsuite(opts \\ [], do: block) do
    quote do
      {:module, name, _, _} =
        defmodule unquote(Module.concat(__MODULE__, :"Test#{System.unique_integer([:positive])}")) do
          use ExUnit.Case, unquote(opts)

          unquote(block)
        end

      name
    end
  end

  describe "suite_finished" do
    setup do
      [event_name: [:ex_unit_telemetry_formatter, :suite_finished]]
    end

    test "total", %{test: test, event_name: event_name} do
      defsuite do
        test "success", do: assert(true)
      end

      self = self()
      attach_telemetry_handler("#{test}", event_name, self)

      run_tests_with_formatter(ExUnitTelemetryFormatter)

      assert_receive {:telemetry_event, ^event_name,
                      %{
                        load: {load, :microseconds},
                        run: {run, :microseconds},
                        total: {total, :microseconds}
                      }, _}
                     when total >= run + load
    end

    test "sync", %{test: test, event_name: event_name} do
      defsuite async: false do
        test "success", do: assert(true)
      end

      self = self()
      attach_telemetry_handler("#{test}", event_name, self)
      run_tests_with_formatter(ExUnitTelemetryFormatter)

      assert_receive {:telemetry_event, ^event_name,
                      %{sync: {sync, :microseconds}, async: {async, :microseconds}}, _}
                     when sync > 0 and async < sync
    end

    test "async", %{test: test, event_name: event_name} do
      defsuite async: true do
        test "success", do: assert(true)
      end

      self = self()
      attach_telemetry_handler("#{test}", event_name, self)
      run_tests_with_formatter(ExUnitTelemetryFormatter)

      assert_receive {:telemetry_event, ^event_name,
                      %{async: {async, :microseconds}, sync: {sync, :microseconds}}, _}
                     when async > 0 and sync < async
    end

    test "metadata", %{test: test, event_name: event_name} do
      defsuite async: true do
        test "success", do: assert(true)
      end

      self = self()
      attach_telemetry_handler("#{test}", event_name, self)
      run_tests_with_formatter(ExUnitTelemetryFormatter, seed: 0)

      assert_receive {:telemetry_event, ^event_name, _, %{seed: 0, total_cases: 1}}
    end
  end

  describe "test_finished" do
    setup do
      [event_name: [:ex_unit_telemetry_formatter, :test_finished]]
    end

    test "time and metadata", %{test: test, event_name: event_name} do
      defsuite do
        test "success", do: assert(true)
      end

      expected_name = :"test success"

      self = self()
      attach_telemetry_handler("#{test}", event_name, self)

      run_tests_with_formatter(ExUnitTelemetryFormatter)

      assert_receive {:telemetry_event, ^event_name, %{time: {time, :microseconds}},
                      %{test: %{name: ^expected_name, module: module}}}
                     when time > 0

      assert to_string(module) =~ "ExUnitTelemetryFormatterTest.Test"
    end
  end

  defp attach_telemetry_handler(handler_id, event_name, pid) do
    :telemetry.attach(
      handler_id,
      event_name,
      fn name, measurements, metadata, _ ->
        send(pid, {:telemetry_event, name, measurements, metadata})
      end,
      nil
    )
  end

  defp run_tests_with_formatter(formatter, opts \\ []) do
    opts
    |> Keyword.merge(formatters: [formatter])
    |> ExUnit.configure()

    ExUnit.run()
  end
end
