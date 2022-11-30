defmodule KeywordValidator do
  @moduledoc """
  Functions for validating keyword lists.

  The main function in this module is `validate/2`, which allows developers to
  validate a keyword list against a given schema.

  A schema is a keyword list that matches the keys for the keyword list.
  The values in the schema represent the options available during validation.

      iex> KeywordValidator.validate([foo: :bar], [foo: [is: :atom]])
      {:ok, [foo: :bar]}

      iex> KeywordValidator.validate([foo: :bar], [foo: [is: :integer]])
      {:error, [foo: ["must be an integer"]]}
  """

  alias KeywordValidator.{Docs, Schema}

  ################################
  # Types
  ################################

  @typedoc """
  Various value `:is` options.
  """
  @type value_is ::
          {:=, any()}
          | :any
          | :atom
          | :binary
          | :bitstring
          | :boolean
          | :float
          | :fun
          | {:fun, arity :: non_neg_integer()}
          | {:in, [any()]}
          | :integer
          | :keyword
          | {:keyword, schema()}
          | :list
          | {:list, value_is()}
          | :map
          | :mfa
          | :mod
          | :mod_args
          | :mod_fun
          | :number
          | {:one_of, [value_is()]}
          | :pid
          | :port
          | :struct
          | {:struct, module()}
          | :timeout
          | :tuple
          | {:tuple, size :: non_neg_integer()}
          | {:tuple, tuple_value_types :: tuple()}

  @typedoc """
  Custom validation logic for key values.
  """
  @type custom_validator ::
          (key :: atom(), value :: any() -> [] | [error :: binary()])
          | {module(), function :: atom()}

  @typedoc """
  Individual value options.
  """
  @type value_opt ::
          {:is, value_is()}
          | {:default, any()}
          | {:required, boolean()}
          | {:custom, [custom_validator()]}
          | {:doc, false | binary()}

  @typedoc """
  All value options.
  """
  @type value_opts :: [value_opt()]

  @typedoc """
  A keyword base schema.
  """
  @type base_schema :: keyword(value_opts())

  @typedoc """
  A keyword schema.
  """
  @type schema :: base_schema() | struct()

  @typedoc """
  An invalid keyword key.
  """
  @type invalid :: keyword([String.t()])

  @typedoc """
  Individual validation options.
  """
  @type option :: {:strict, boolean()}

  @typedoc """
  All validation options.
  """
  @type options :: [option()]

  ################################
  # Public API
  ################################

  @doc """
  Prepares a schema or raises an `ArgumentError` exception if invalid.

  A schema is a keyword list of keys and value options.

  This is the preferred method of providing a validation schema as it ensures
  your schema is valid and avoids running additional validation on each invocation.
  You can then declare your schema as a module attribute:

      @opts_schema KeywordValidator.schema!([...])

      KeywordValidator.validate!(keyword, @opts_schema)

  ## Value Options

  #{KeywordValidator.Docs.build(Schema.schema())}

  ## Is Options

  The following value types are available for use with the `:is` option:

  * `{:=, value}` - Equal to value.
  * `:any` - Any value.
  * `:atom` - An atom.
  * `:binary` - A binary.
  * `:bitstring` - A bitstring.
  * `:boolean` - A boolean.
  * `:float` - A float.
  * `:fun` - A function.
  * `{:fun, arity}` - A function with specified arity.
  * `{:in, [value]}` - In the list of values.
  * `:integer` - An integer.
  * `:keyword` - A keyword list.
  * `{:keyword, schema}` - A keyword with the provided schema.
  * `:list` - A list.
  * `:map` - A map.
  * `:mfa` - A module, function and args.
  * `:mod_args` - A module and args.
  * `:mod_fun` - A module and function.
  * `:mod` - A module.
  * `:number` - A number.
  * `{:one_of, [type]}` - Any one of the provided types.
  * `:pid` - A PID.
  * `:port` - A port.
  * `:struct` - A struct.
  * `{:struct, type}` - A struct of the provided type.
  * `:timeout` - A timeout (integer or `:infinite`).
  * `:tuple` - A tuple.
  * `{:tuple, size}` - A tuple of the provided size.
  * `{:tuple, tuple}` - A tuple with the provided tuple types.
  """
  @spec schema!(base_schema()) :: struct()
  def schema!(schema) do
    case Schema.new(schema) do
      {:ok, schema} ->
        schema

      {:error, {:invalid, key}} ->
        raise ArgumentError, """
        Options given for schema key #{inspect(key)} are invalid.
        """

      {:error, :invalid} ->
        raise ArgumentError, """
        Invalid schema. Must be a keyword list.
        """
    end
  end

  @doc """
  Validates a keyword list using the provided schema.

  A schema is a keyword list (or prepared schema via `schema!/1`) - with each key
  representing a key in your keyword list. The values in the schema keyword list
  represent the options available for validation.

  If the validation passes, we are returned a two-item tuple of `{:ok, keyword}`.
  Otherwise, returns `{:error, invalid}` - where `invalid` is a keyword list of errors.

  ## Schema

  Please see `schema!/1` for options available when building schemas.

  ## Options

    * `:strict` - Boolean representing whether extra keys will become errors. Defaults to `true`.

  ## Examples

      iex> KeywordValidator.validate([foo: :foo], [foo: [is: :atom, required: true]])
      {:ok, [foo: :foo]}

      iex> KeywordValidator.validate([foo: :foo], [bar: [is: :any]])
      {:error, [foo: ["is not a valid key"]]}

      iex> KeywordValidator.validate([foo: :foo], [bar: [is: :any]], strict: false)
      {:ok, []}

      iex> KeywordValidator.validate([foo: :foo], [foo: [is: {:in, [:one, :two]}]])
      {:error, [foo: ["must be one of: [:one, :two]"]]}

      iex> KeywordValidator.validate([foo: {:foo, 1}], [foo: [is: {:tuple, {:atom, :integer}}]])
      {:ok, [foo: {:foo, 1}]}

      iex> KeywordValidator.validate([foo: ["one", 2]], [foo: [is: {:list, :binary}]])
      {:error, [foo: ["must be a list of type :binary"]]}

      iex> KeywordValidator.validate([foo: %Foo{}], [foo: [is: {:struct, Bar}]])
      {:error, [foo: ["must be a struct of type Bar"]]}

      iex> KeywordValidator.validate([foo: "foo"], [foo: [is: :any, custom: [fn key, val -> ["some error"] end]]])
      {:error, [foo: ["some error"]]}

  """
  @spec validate(keyword(), schema(), options()) :: {:ok, keyword()} | {:error, invalid()}
  def validate(keyword, schema, opts \\ [])

  def validate(keyword, %Schema{schema: schema}, opts) when is_list(keyword) do
    strict = Keyword.get(opts, :strict, true)
    valid = []
    invalid = []

    {keyword, valid, invalid}
    |> validate_extra_keys(schema, strict)
    |> validate_keys(schema)
    |> to_tagged_tuple()
  end

  def validate(keyword, schema, opts) do
    schema = schema!(schema)
    validate(keyword, schema, opts)
  end

  @doc """
  The same as `validate/2` but raises an `ArgumentError` exception if invalid.

  ## Example

      iex> KeywordValidator.validate!([foo: :bar], [foo: [is: :atom, required: true]])
      [foo: :foo]

      iex> KeywordValidator.validate!([foo: "bar"], [foo: [is: :atom, required: true]])
      ** (ArgumentError) Invalid keyword given.

      Keyword:

      [foo: "bar"]

      Invalid:

      foo: ["must be an atom"]
  """
  @spec validate!(keyword(), schema(), options()) :: Keyword.t()
  def validate!(keyword, schema, opts \\ []) do
    case validate(keyword, schema, opts) do
      {:ok, valid} ->
        valid

      {:error, invalid} ->
        raise ArgumentError, """
        Invalid keyword given.

        Keyword:

        #{inspect(keyword, pretty: true)}

        Invalid:

        #{format_invalid(invalid)}
        """
    end
  end

  @doc ~S"""
  Builds documentation for a given schema.

  This can be used to inject documentation in your docstrings. For example:

      @options_schema KeywordValidator.schema!([key: [type: :any, doc: "Some option."]])

      @doc "Options:\n#{KeywordValidator.docs(@options_schema)}"

  This will automatically generate documentation that includes information on
  required keys and default values.
  """
  @spec docs(schema()) :: binary()
  def docs(%Schema{} = schema), do: Docs.build(schema)
  def docs(schema), do: schema |> schema!() |> docs()

  ################################
  # Private API
  ################################

  defp validate_extra_keys(results, _schema, false), do: results

  defp validate_extra_keys({keyword, _valid, _invalid} = results, schema, true) do
    Enum.reduce(keyword, results, fn {key, _val}, {keyword, valid, invalid} ->
      if Keyword.has_key?(schema, key) do
        {keyword, valid, invalid}
      else
        {keyword, valid, put_error(invalid, key, "is not a valid key")}
      end
    end)
  end

  defp put_error(invalid, key, msg) when is_binary(msg) do
    Keyword.update(invalid, key, [msg], fn errors ->
      [msg | errors]
    end)
  end

  defp put_error(invalid, key, msgs) when is_list(msgs) do
    Enum.reduce(msgs, invalid, &put_error(&2, key, &1))
  end

  defp validate_keys(result, schema) do
    Enum.reduce(schema, result, &maybe_validate_key(&1, &2))
  end

  defp maybe_validate_key({key, opts}, {keyword, valid, invalid}) do
    if validate_key?(keyword, key, opts) do
      validate_key({key, opts}, {keyword, valid, invalid})
    else
      {keyword, valid, invalid}
    end
  end

  defp validate_key?(keyword, key, opts) do
    Keyword.has_key?(keyword, key) || opts.required || opts.default != nil
  end

  defp validate_key({key, opts}, {keyword, valid, invalid}) do
    val = Keyword.get(keyword, key, opts.default)

    {key, opts, val, []}
    |> validate_required()
    |> validate_is()
    |> validate_custom()
    |> case do
      {key, _, val, []} -> {keyword, [{key, val} | valid], invalid}
      {key, _, _, errors} -> {keyword, valid, put_error(invalid, key, errors)}
    end
  end

  defp validate_required({key, %{required: true} = opts, nil, errors}) do
    {key, opts, nil, ["is a required key" | errors]}
  end

  defp validate_required(validation) do
    validation
  end

  defp validate_is({key, opts, val, errors}) do
    case validate_is(opts.is, val) do
      {:ok, val} -> {key, opts, val, errors}
      {:error, msg} -> {key, opts, val, [msg | errors]}
    end
  end

  defp validate_is({:=, val1}, val2) when val1 == val2, do: {:ok, val2}
  defp validate_is({:=, val}, _val), do: {:error, "must be equal to: #{inspect(val)}"}

  defp validate_is(:any, val), do: {:ok, val}

  defp validate_is(:atom, val) when is_atom(val) and not is_nil(val), do: {:ok, val}
  defp validate_is(:atom, _val), do: {:error, "must be an atom"}

  defp validate_is(:binary, val) when is_binary(val), do: {:ok, val}
  defp validate_is(:binary, _val), do: {:error, "must be a binary"}

  defp validate_is(:bitstring, val) when is_bitstring(val), do: {:ok, val}
  defp validate_is(:bitstring, _val), do: {:error, "must be a bitstring"}

  defp validate_is(:boolean, val) when is_boolean(val), do: {:ok, val}
  defp validate_is(:boolean, _val), do: {:error, "must be a boolean"}

  defp validate_is({:in, vals}, val) when is_list(vals) do
    if val in vals do
      {:ok, val}
    else
      {:error, "must be one of: #{inspect(vals)}"}
    end
  end

  defp validate_is(:float, val) when is_float(val), do: {:ok, val}
  defp validate_is(:float, _val), do: {:error, "must be a float"}

  defp validate_is(:fun, val) when is_function(val), do: {:ok, val}
  defp validate_is(:fun, _val), do: {:error, "must be a function"}

  defp validate_is({:fun, arity}, val) when is_function(val, arity), do: {:ok, val}

  defp validate_is({:fun, arity}, _val),
    do: {:error, "must be a function of arity #{arity}"}

  defp validate_is(:integer, val) when is_integer(val), do: {:ok, val}
  defp validate_is(:integer, _val), do: {:error, "must be an integer"}

  defp validate_is(:keyword, val) when is_list(val) do
    Enum.reduce_while(val, {:ok, val}, fn
      {key, _}, acc when is_atom(key) -> {:cont, acc}
      _, _ -> {:halt, {:error, "must be a keyword list"}}
    end)
  end

  defp validate_is(:keyword, _val), do: {:error, "must be a keyword list"}

  defp validate_is({:keyword, schema}, val) when is_list(val) do
    case validate(val, schema) do
      {:ok, val} -> {:ok, val}
      {:error, _errors} -> {:error, "must be a keyword with structure: #{schema_string(schema)}"}
    end
  end

  defp validate_is({:keyword, schema}, _val) do
    {:error, "must be a keyword with structure: #{schema_string(schema)}"}
  end

  defp validate_is(:list, val) when is_list(val), do: {:ok, val}
  defp validate_is(:list, _val), do: {:error, "must be a list"}

  defp validate_is({:list, type}, val) when is_list(val) do
    Enum.reduce_while(val, {:ok, []}, fn item, {:ok, acc} ->
      case validate_is(type, item) do
        {:ok, val} -> {:cont, {:ok, acc ++ [val]}}
        {:error, _} -> {:halt, {:error, "must be a list of type #{inspect(type)}"}}
      end
    end)
  end

  defp validate_is({:list, type}, _val), do: {:error, "must be a list of type #{inspect(type)}"}

  defp validate_is(:map, val) when is_map(val), do: {:ok, val}
  defp validate_is(:map, _val), do: {:error, "must be a map"}

  defp validate_is(:mfa, {mod, fun, args} = val)
       when is_atom(mod) and not is_nil(mod) and is_atom(fun) and not is_nil(fun) and
              is_list(args) do
    {:ok, val}
  end

  defp validate_is(:mfa, _val), do: {:error, "must be a mfa"}

  defp validate_is(:mod, val) when is_atom(val) and not is_nil(val) do
    {:ok, val}
  end

  defp validate_is(:mod, _val), do: {:error, "must be a module"}

  defp validate_is(:mod_args, {mod, args} = val)
       when is_atom(mod) and not is_nil(mod) and is_list(args) do
    {:ok, val}
  end

  defp validate_is(:mod_args, _val), do: {:error, "must be a module and args"}

  defp validate_is(:mod_fun, {mod, fun} = val)
       when is_atom(mod) and not is_nil(mod) and is_atom(fun) and not is_nil(fun) do
    {:ok, val}
  end

  defp validate_is(:mod_fun, _val), do: {:error, "must be a module and function"}

  defp validate_is(:number, val) when is_number(val), do: {:ok, val}
  defp validate_is(:number, _val), do: {:error, "must be a number"}

  defp validate_is({:one_of, types}, val) when is_list(types) do
    error = {:error, "must be one of the following: #{inspect(types)}"}

    Enum.reduce_while(types, error, fn type, acc ->
      case validate_is(type, val) do
        {:ok, _} = success -> {:halt, success}
        {:error, _} -> {:cont, acc}
      end
    end)
  end

  defp validate_is(:pid, val) when is_pid(val), do: {:ok, val}
  defp validate_is(:pid, _val), do: {:error, "must be a PID"}

  defp validate_is(:port, val) when is_port(val), do: {:ok, val}
  defp validate_is(:port, _val), do: {:error, "must be a port"}

  defp validate_is(:struct, %{__struct__: _} = val), do: {:ok, val}
  defp validate_is(:struct, _val), do: {:error, "must be a struct"}

  defp validate_is({:struct, type1}, %{__struct__: type2} = val) when type1 == type2,
    do: {:ok, val}

  defp validate_is({:struct, type}, _val),
    do: {:error, "must be a struct of type #{inspect(type)}"}

  defp validate_is(:timeout, val) when is_integer(val), do: {:ok, val}
  defp validate_is(:timeout, :infinity = val), do: {:ok, val}
  defp validate_is(:timeout, _val), do: {:error, "must be a timeout"}

  defp validate_is(:tuple, val) when is_tuple(val), do: {:ok, val}
  defp validate_is(:tuple, _val), do: {:error, "must be a tuple"}

  defp validate_is({:tuple, size}, val)
       when is_tuple(val) and is_integer(size) and tuple_size(val) == size,
       do: {:ok, val}

  defp validate_is({:tuple, size}, _val) when is_integer(size),
    do: {:error, "must be a tuple of size #{size}"}

  defp validate_is({:tuple, types}, val)
       when is_tuple(types) and is_tuple(val) and tuple_size(types) == tuple_size(val) do
    type_list = Tuple.to_list(types)
    val_list = Tuple.to_list(val)
    validations = Enum.zip(type_list, val_list)

    Enum.reduce_while(validations, {:ok, {}}, fn {type, val}, {:ok, acc} ->
      case validate_is(type, val) do
        {:ok, val} -> {:cont, {:ok, Tuple.append(acc, val)}}
        {:error, _} -> {:halt, {:error, "must be a tuple with the structure: #{inspect(types)}"}}
      end
    end)
  end

  defp validate_is({:tuple, type}, _val),
    do: {:error, "must be a tuple with the structure: #{inspect(type)}"}

  defp validate_custom({_, %{custom: []}, _, _} = validation) do
    validation
  end

  defp validate_custom({key, %{custom: custom} = opts, val, errors}) do
    errors = Enum.reduce(custom, errors, &validate_custom(&1, key, val, &2))
    {key, opts, val, errors}
  end

  defp validate_custom({module, fun}, key, val, errors) do
    apply(module, fun, [key, val]) ++ errors
  end

  defp validate_custom(validator, key, val, errors) when is_function(validator, 2) do
    validator.(key, val) ++ errors
  end

  defp to_tagged_tuple({_, valid, []}), do: {:ok, Enum.reverse(valid)}
  defp to_tagged_tuple({_, _, invalid}), do: {:error, invalid}

  defp format_invalid(invalid) do
    invalid
    |> Enum.reduce("", fn {key, errors}, final ->
      final <> "#{key}: #{inspect(errors, pretty: true)}\n"
    end)
    |> String.trim_trailing("\n")
  end

  defp schema_string(schema) do
    schema = Enum.map_join(schema, ", ", fn {k, v} -> "#{k}: #{inspect(v)}" end)
    "[#{schema}]"
  end
end
