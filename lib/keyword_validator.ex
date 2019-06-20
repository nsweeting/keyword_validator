defmodule KeywordValidator do
  @moduledoc """
  Functions for validating keyword lists.

  The main function in this module is `validate/2`, which allows developers to
  validate a keyword list against a given schema.

  A schema is simply a map that matches the keys for the keyword list. The values
  in the schema represent the options available during validation.

      iex> KeywordValidator.validate([foo: :foo], %{foo: [type: :atom, required: true]})
      {:ok, [foo: :foo]}

      iex> KeywordValidator.validate([foo: :foo], %{foo: [inclusion: [:one, :two]]})
      {:error, [foo: ["must be one of: [:one, :two]"]]}

  """

  @type val_type ::
          :any
          | :atom
          | :binary
          | :bitstring
          | :boolean
          | :float
          | :function
          | {:function, arity :: non_neg_integer()}
          | :integer
          | {:keyword, schema()}
          | :list
          | {:list, val_type()}
          | :map
          | :mfa
          | :module
          | :number
          | :pid
          | :port
          | :struct
          | {:struct, module()}
          | :tuple
          | {:tuple, size :: non_neg_integer()}
          | {:tuple, tuple_val_types :: tuple()}
  @type key_opt ::
          {:default, any()}
          | {:required, boolean()}
          | {:type, val_type() | [val_type()]}
          | {:format, Regex.t()}
          | {:custom, (atom(), any() -> [] | [binary()]) | {module(), atom()}}
          | {:inclusion, list()}
          | {:exclusion, list()}
  @type key_opts :: [key_opt()]
  @type schema :: %{atom() => key_opts()}
  @type invalid :: [{atom(), [String.t()]}]
  @type option :: {:strict, boolean()}
  @type options :: [option()]

  @default_key_opts [
    default: nil,
    required: false,
    type: :any,
    format: nil,
    custom: [],
    inclusion: [],
    exclusion: []
  ]

  @doc """
  Validates a keyword list using the provided schema.

  A schema is a simple map, with each key representing a key in your keyword list.
  The values in the map represent the options available for validation.

  If the validation passes, we are returned a two-item tuple of `{:ok, keyword}`.
  Otherwise, returns `{:error, invalid}` - where `invalid` is a keyword list of errors.

  ## Schema Options

    * `:required` - boolean representing whether the key is required or not, defaults to `false`
    * `:default` - the default value for the key if not provided one, defaults to `nil`
    * `:type` - the type associated with the key value. must be one of `t:val_type/0`
    * `:format` - a regex used to validate string format
    * `:inclusion` - a list of items that the value must be a included in
    * `:exclusion` - a list of items that the value must not be included in
    * `:custom` - a list of two-arity functions or tuples in the format `{module, function}`
       that serve as custom validators. the function will be given the key and value as
       arguments, and must return a list of string errors (or an empty list if no errors are present)

  ## Options

    * `:strict` - boolean representing whether extra keys will become errors, defaults to `true`

  ## Examples

      iex> KeywordValidator.validate([foo: :foo], %{foo: [type: :atom, required: true]})
      {:ok, [foo: :foo]}

      iex> KeywordValidator.validate([foo: :foo], %{bar: [type: :any]})
      {:error, [foo: ["is not a valid key"]]}

      iex> KeywordValidator.validate([foo: :foo], %{bar: [type: :any]}, strict: false)
      {:ok, []}

      iex> KeywordValidator.validate([foo: :foo], %{foo: [inclusion: [:one, :two]]})
      {:error, [foo: ["must be one of: [:one, :two]"]]}

      iex> KeywordValidator.validate([foo: {:foo, 1}], %{foo: [type: {:tuple, {:atom, :integer}}]})
      {:ok, [foo: {:foo, 1}]}

      iex> KeywordValidator.validate([foo: ["one", 2]], %{foo: [type: {:list, :binary}]})
      {:error, [foo: ["must be a list of type :binary"]]}

      iex> KeywordValidator.validate([foo: "foo"], %{foo: [format: ~r/foo/]})
      {:ok, [foo: "foo"]}

      iex> KeywordValidator.validate([foo: %Foo{}], %{foo: [type: {:struct, Bar}]})
      {:error, [foo: ["must be a struct of type Bar"]]}

      iex> KeywordValidator.validate([foo: "foo"], %{foo: [custom: [fn key, val -> ["some error"] end]]})
      {:error, [foo: ["some error"]]}

  """
  @spec validate(keyword(), schema(), options()) :: {:ok, keyword()} | {:error, invalid()}
  def validate(keyword, schema, opts \\ []) when is_list(keyword) and is_map(schema) do
    strict = Keyword.get(opts, :strict, true)

    {[], keyword, []}
    |> validate_extra_keys(schema, strict)
    |> validate_keys(schema)
    |> to_tagged_tuple()
  end

  @doc """
  The same as `validate/2` but raises an `ArgumentError` exception if invalid.

  ## Example

      iex> KeywordValidator.validate!([foo: :foo], %{foo: [type: :atom, required: true]})
      [foo: :foo]

      iex> KeywordValidator.validate!([foo: :foo], %{foo: [inclusion: [:one, :two]]})
      ** (ArgumentError) Invalid keyword given.

      Keyword:

      [foo: :foo]

      Invalid:

      foo: ["must be one of: [:one, :two]"]

  """
  @spec validate!(keyword(), schema(), options()) :: Keyword.t()
  def validate!(keyword, schema, opts \\ []) do
    case validate(keyword, schema, opts) do
      {:ok, parsed} ->
        parsed

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

  defp validate_extra_keys(results, _schema, false) do
    results
  end

  defp validate_extra_keys({_parsed, keyword, _invalid} = results, schema, true) do
    Enum.reduce(keyword, results, fn {key, _val}, {parsed, keyword, invalid} ->
      if Map.has_key?(schema, key) do
        {parsed, keyword, invalid}
      else
        {parsed, keyword, put_error(invalid, key, "is not a valid key")}
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

  defp maybe_validate_key({key, opts}, {parsed, keyword, invalid}) do
    opts = @default_key_opts |> Keyword.merge(opts) |> Enum.into(%{})

    if validate_key?(keyword, key, opts) do
      validate_key({key, opts}, {parsed, keyword, invalid})
    else
      {parsed, keyword, invalid}
    end
  end

  defp validate_key?(keyword, key, opts) do
    Keyword.has_key?(keyword, key) || opts.required || opts.default
  end

  defp validate_key({key, opts}, {parsed, keyword, invalid}) do
    val = Keyword.get(keyword, key, opts.default)

    {key, opts, val, []}
    |> validate_required()
    |> validate_type()
    |> validate_format()
    |> validate_inclusion()
    |> validate_exclusion()
    |> validate_custom()
    |> case do
      {key, _, val, []} -> {Keyword.put(parsed, key, val), keyword, invalid}
      {key, _, _, errors} -> {parsed, keyword, put_error(invalid, key, errors)}
    end
  end

  defp validate_required({key, %{required: true} = opts, nil, errors}) do
    {key, opts, nil, ["is a required key" | errors]}
  end

  defp validate_required(validation) do
    validation
  end

  defp validate_type({key, opts, val, errors}) do
    case validate_type(opts.type, val) do
      {:ok, val} -> {key, opts, val, errors}
      {:error, msg} -> {key, opts, val, [msg | errors]}
    end
  end

  defp validate_type(:any, val), do: {:ok, val}

  defp validate_type(:atom, val) when is_atom(val) and not is_nil(val), do: {:ok, val}
  defp validate_type(:atom, _val), do: {:error, "must be an atom"}

  defp validate_type(:binary, val) when is_binary(val), do: {:ok, val}
  defp validate_type(:binary, _val), do: {:error, "must be a binary"}

  defp validate_type(:bitstring, val) when is_bitstring(val), do: {:ok, val}
  defp validate_type(:bitstring, _val), do: {:error, "must be a bitstring"}

  defp validate_type(:boolean, val) when is_boolean(val), do: {:ok, val}
  defp validate_type(:boolean, _val), do: {:error, "must be a boolean"}

  defp validate_type(:float, val) when is_float(val), do: {:ok, val}
  defp validate_type(:float, _val), do: {:error, "must be a float"}

  defp validate_type(:function, val) when is_function(val), do: {:ok, val}
  defp validate_type(:function, _val), do: {:error, "must be a function"}
  defp validate_type({:function, arity}, val) when is_function(val, arity), do: {:ok, val}

  defp validate_type({:function, arity}, _val),
    do: {:error, "must be a function of arity #{arity}"}

  defp validate_type(:integer, val) when is_integer(val), do: {:ok, val}
  defp validate_type(:integer, _val), do: {:error, "must be an integer"}

  defp validate_type({:keyword, schema}, val) when is_list(val) do
    case validate(val, schema) do
      {:ok, val} -> {:ok, val}
      {:error, _errors} -> {:error, "must be a keyword with structure: #{schema_string(schema)}"}
    end
  end

  defp validate_type({:keyword, schema}, _val) do
    {:error, "must be a keyword with structure: #{schema_string(schema)}"}
  end

  defp validate_type(:list, val) when is_list(val), do: {:ok, val}
  defp validate_type(:list, _val), do: {:error, "must be a list"}

  defp validate_type({:list, type}, val) when is_list(val) do
    Enum.reduce_while(val, {:ok, []}, fn item, {:ok, acc} ->
      case validate_type(type, item) do
        {:ok, val} -> {:cont, {:ok, acc ++ [val]}}
        {:error, _} -> {:halt, {:error, "must be a list of type #{inspect(type)}"}}
      end
    end)
  end

  defp validate_type({:list, type}, _val), do: {:error, "must be a list of type #{inspect(type)}"}

  defp validate_type(:map, val) when is_map(val), do: {:ok, val}
  defp validate_type(:map, _val), do: {:error, "must be a map"}

  defp validate_type(:mfa, {mod, fun, arg} = val)
       when is_atom(mod) and not is_nil(mod) and is_atom(fun) and not is_nil(fun) and is_list(arg) do
    if Code.ensure_loaded?(mod) and function_exported?(mod, fun, length(arg)) do
      {:ok, val}
    else
      {:error, "must be a mfa"}
    end
  end

  defp validate_type(:mfa, _val), do: {:error, "must be a mfa"}

  defp validate_type(:module, val) when is_atom(val) and not is_nil(val) do
    if Code.ensure_loaded?(val) do
      {:ok, val}
    else
      {:error, "must be a module"}
    end
  end

  defp validate_type(:module, _val), do: {:error, "must be a module"}

  defp validate_type(:number, val) when is_number(val), do: {:ok, val}
  defp validate_type(:number, _val), do: {:error, "must be a number"}

  defp validate_type(:pid, val) when is_pid(val), do: {:ok, val}
  defp validate_type(:pid, _val), do: {:error, "must be a PID"}

  defp validate_type(:port, val) when is_port(val), do: {:ok, val}
  defp validate_type(:port, _val), do: {:error, "must be a port"}

  defp validate_type(:struct, %{__struct__: _} = val), do: {:ok, val}
  defp validate_type(:struct, _val), do: {:error, "must be a struct"}

  defp validate_type({:struct, type1}, %{__struct__: type2} = val) when type1 == type2,
    do: {:ok, val}

  defp validate_type({:struct, type}, _val),
    do: {:error, "must be a struct of type #{inspect(type)}"}

  defp validate_type(:tuple, val) when is_tuple(val), do: {:ok, val}
  defp validate_type(:tuple, _val), do: {:error, "must be a tuple"}

  defp validate_type({:tuple, size}, val)
       when is_tuple(val) and is_integer(size) and tuple_size(val) == size,
       do: {:ok, val}

  defp validate_type({:tuple, size}, _val) when is_integer(size),
    do: {:error, "must be a tuple of size #{size}"}

  defp validate_type({:tuple, types}, val)
       when is_tuple(types) and is_tuple(val) and tuple_size(types) == tuple_size(val) do
    type_list = Tuple.to_list(types)
    val_list = Tuple.to_list(val)
    validations = Enum.zip(type_list, val_list)

    Enum.reduce_while(validations, {:ok, {}}, fn {type, val}, {:ok, acc} ->
      case validate_type(type, val) do
        {:ok, val} -> {:cont, {:ok, Tuple.append(acc, val)}}
        {:error, _} -> {:halt, {:error, "must be a tuple with the structure: #{inspect(types)}"}}
      end
    end)
  end

  defp validate_type({:tuple, type}, _val),
    do: {:error, "must be a tuple with the structure: #{inspect(type)}"}

  defp validate_type(types, val) when is_list(types) do
    error = {:error, "must be one of the following: #{inspect(types)}"}

    Enum.reduce_while(types, error, fn type, acc ->
      case validate_type(type, val) do
        {:ok, _} = success -> {:halt, success}
        {:error, _} -> {:cont, acc}
      end
    end)
  end

  defp validate_format({key, %{format: %Regex{} = format} = opts, val, errors}) do
    if val =~ format do
      {key, opts, val, errors}
    else
      {key, opts, val, ["has invalid format" | errors]}
    end
  end

  defp validate_format(validation) do
    validation
  end

  defp validate_inclusion({_, %{inclusion: []}, _, _} = validation) do
    validation
  end

  defp validate_inclusion({key, %{inclusion: inclusion} = opts, val, errors}) do
    if Enum.member?(inclusion, val) do
      {key, opts, val, errors}
    else
      {key, opts, val, ["must be one of: #{inspect(inclusion)}" | errors]}
    end
  end

  defp validate_exclusion({_, %{exclusion: []}, _, _} = validation) do
    validation
  end

  defp validate_exclusion({key, %{exclusion: exclusion} = opts, val, errors}) do
    if Enum.member?(exclusion, val) do
      {key, opts, val, ["must not be one of: #{inspect(exclusion)}" | errors]}
    else
      {key, opts, val, errors}
    end
  end

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

  defp to_tagged_tuple({parsed, _, []}), do: {:ok, parsed}
  defp to_tagged_tuple({_, _, invalid}), do: {:error, invalid}

  defp format_invalid(invalid) do
    invalid
    |> Enum.reduce("", fn {key, errors}, final ->
      final <> "#{key}: #{inspect(errors, pretty: true)}\n"
    end)
    |> String.trim_trailing("\n")
  end

  defp schema_string(schema) do
    schema =
      schema
      |> Enum.map(fn {k, v} -> "#{k}: #{inspect(v)}" end)
      |> Enum.join(", ")

    "[#{schema}]"
  end
end
