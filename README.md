# WIP: Excoverage

[![Build Status](https://travis-ci.org/RJSkorski/excoverage.svg?branch=master)](https://travis-ci.org/RJSkorski/excoverage)

A tool for calculating test coverage using ExUnit for running tests.
For now it calculates function coverage only.

To do:

  - calculating line & branch coverage

## Installation

The package can be installed by adding `excoverage` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:excoverage, "~> 0.1.0"}
  ]
end
```

There are two possible way of using this tool:

- by setting a test coverage tool in mix.exs configuration file:

```elixir
def project do
  [
    ...
    test_coverage: [tool: Excoverage],
    ...
  ]
```
and running:

```shell
mix test --cover
```

- by running:

```shell
mix excoverage
```

## Documentation

The docs can be found at [https://hexdocs.pm/excoverage](https://hexdocs.pm/excoverage).
