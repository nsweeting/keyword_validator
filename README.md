# KeywordValidator

[![Build Status](https://travis-ci.org/nsweeting/keyword_validator.svg?branch=master)](https://travis-ci.org/nsweeting/keyword_validator)
[![StatBuffer Version](https://img.shields.io/hexpm/v/keyword_validator.svg)](https://hex.pm/packages/keyword_validator)

KeywordValidator provides a simple interface to validate keyword lists in Elixir.

## Installation

The package can be installed by adding `keyword_validator` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:keyword_validator, "~> 0.1"}
  ]
end
```

## Documentation

Please see [HexDocs](https://hexdocs.pm/keyword_validator) for additional documentation.

## Getting Started

To begin validating, we must first create a schema that defines the rules for our
keyword list.

A schema is a simple map, with each key representing a key in your keyword list.
The values in the map represent the options available for validation. If the validation
passes, we are returned a valid keyword list.

```elixir
iex> keyword = [foo: :foo, bar: "one"]
iex> schema = %{foo: [type: :atom, required: true], bar: [inclusion: ["one", "two", "three"]]}
iex> KeywordValidator.validate(keyword, schema)
{:ok, [foo: :foo, bar: "one"]}
```

If validation fails on any of the keys, a keyword list of the invalid entries and the
associated errors is returned.

```elixir
iex> keyword = [foo: :foo, bar: :bar]
iex> schema = %{foo: [type: :binary], bar: [inclusion: [:one, :two, :three]]}
iex> KeywordValidator.validate(keyword, schema)
{:error, [bar: ["must be one of: [:one, :two, :three]"], foo: ["must be a binary"]]}
```

We can optionally use the `KeywordValidator.validate!/2` function as well - which will raise
an error that describes the invalid key entries.

```elixir
** (ArgumentError) Invalid keyword given.

Keyword:

[foo: :foo, bar: :bar]

Invalid:

bar: ["must be one of: [:one, :two, :three]"]
foo: ["must be a binary"]
```

To view all the available validation options, please check out the [relevant documentation](https://hexdocs.pm/keyword_validator/KeywordValidator.html#validate/2).