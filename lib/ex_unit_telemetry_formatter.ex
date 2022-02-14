defmodule ExUnitTelemetryFormatter do
  @moduledoc """
  An ExUnit formatter that emits telemetry events for a test suite.

  ## Events

  ### [:ex_unit_telemetry_formatter, :suite_finished]

  Emitted when a ExUnit test suite finishes.

  #### Measurements

  All measurement values are tuples containing the time and the time unit, example: `{357900, :microsecond}`

  * `run` - the run time of the suite
  * `load` - the time taken to load tests
  * `async` - the time taken for asynchronous tests
  * `sync` - time taken for synchronous tests (run - async)
  * `total` - total run time of the suite (run + load)

  #### Metadata

    * `seed` - the seed of the test suite
    * `total_cases` - the number of test cases in the suite

  ### [:ex_unit_telemetry_formatter, :test_finished]

  Emitted every time a test case finishes.

  #### Measurements

  * `time` - A tuple containg the time taken of the test case and the time unit

  #### Metadata

  * `test` - A map containing test details
      * `name` - Name of the test case
      * `module` - Module containing the test case
      * `tags` - Tags of the test case

  """
  use GenServer

  defstruct [:seed, :total_cases]

  @event_name_base [:ex_unit_telemetry_formatter]

  # Measurements from exunit is in microseconds
  @exunit_time_unit :microsecond

  @impl true
  def init(opts) do
    {:ok, %__MODULE__{seed: opts[:seed], total_cases: 0}}
  end

  @impl true
  def handle_cast({:suite_started, _opts}, config) do
    {:noreply, config}
  end

  @impl true
  def handle_cast({:suite_finished = event_name, times_us}, config) do
    measurements = %{
      run: {times_us.run, @exunit_time_unit},
      async: {times_us.async || 0, @exunit_time_unit},
      load: {times_us.load || 0, @exunit_time_unit},
      sync: {times_us.run - (times_us.async || 0), @exunit_time_unit},
      total: {times_us.run + (times_us.load || 0), @exunit_time_unit}
    }

    :telemetry.execute(
      @event_name_base ++ [event_name],
      measurements,
      %{seed: config.seed, total_cases: config.total_cases}
    )

    {:noreply, config}
  end

  def handle_cast({:module_started, _test_module}, config) do
    {:noreply, config}
  end

  def handle_cast({:module_finished, _test_module}, config) do
    # https://hexdocs.pm/ex_unit/1.13/ExUnit.TestModule.html
    {:noreply, config}
  end

  def handle_cast({:test_started, _test}, config) do
    {:noreply, config}
  end

  def handle_cast({:test_finished = event_name, test}, config) do
    measurements = %{
      time: {test.time, @exunit_time_unit}
    }

    metadata = %{
      name: test.name,
      module: test.module,
      tags: test.tags
    }

    :telemetry.execute(
      @event_name_base ++ [event_name],
      measurements,
      %{seed: config.seed, test: metadata}
    )

    {:noreply, %__MODULE__{config | total_cases: config.total_cases + 1}}
  end

  # {:sigquit, [test | test_module]} - the VM is going to shutdown. It receives the test cases (or test module in case of setup_all) still running.
  def handle_cast({:sigquit, _}, config) do
    {:noreply, config}
  end

  # The formatter will also receive the following events but they are deprecated and should be ignored:
  def handle_cast({:case_started, _test_module}, config), do: {:noreply, config}
  def handle_cast({:case_finished, _test_module}, config), do: {:noreply, config}
end
