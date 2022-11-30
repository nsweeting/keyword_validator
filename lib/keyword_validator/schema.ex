defmodule KeywordValidator.Schema.Value do
  @moduledoc false

  ################################
  # Types
  ################################

  defstruct is: :any, default: nil, required: false, custom: [], doc: false

  @opaque t :: %__MODULE__{
            is: KeywordValidator.value_is(),
            default: any(),
            required: boolean(),
            custom: [KeywordValidator.custom_validator()],
            doc: false | binary()
          }

  ################################
  # Public API
  ################################

  @doc false
  @spec new(keyword()) :: KeywordValidator.Schema.Value.t()
  def new(value), do: struct(__MODULE__, value)
end

defmodule KeywordValidator.Schema do
  @moduledoc false

  alias KeywordValidator.Schema.Value

  ################################
  # Module Attributes
  ################################

  @opts_schema [
    is:
      Value.new(
        is:
          {:one_of,
           [
             {:in,
              [
                :any,
                :atom,
                :binary,
                :bitstring,
                :boolean,
                :float,
                :fun,
                :integer,
                :keyword,
                :list,
                :map,
                :mfa,
                :mod,
                :mod_args,
                :mod_fun,
                :number,
                :port,
                :pid,
                :struct,
                :timeout,
                :tuple
              ]},
             {:tuple, {{:=, :fun}, :integer}},
             {:tuple, {{:=, :keyword}, {:one_of, [:keyword, {:struct, KeywordValidator}]}}},
             {:tuple, {{:=, :list}, {:one_of, [:tuple, :atom]}}},
             {:tuple, {{:=, :struct}, :mod}},
             {:tuple, {{:=, :tuple}, {:one_of, [:integer, :tuple]}}},
             {:tuple, {{:=, :in}, :list}},
             {:tuple, {{:=, :one_of}, :list}},
             {:tuple, {{:=, :=}, :any}}
           ]},
        doc:
          "The value type associated with the key. Must be one of `t:KeywordValidator.value_is/0`.",
        default: :any
      ),
    default: Value.new(is: :any, doc: "The default value for the key if not provided one."),
    required:
      Value.new(
        is: :boolean,
        default: false,
        doc: "Boolean representing whether the key is required or not."
      ),
    custom:
      Value.new(
        is: {:list, {:one_of, [{:fun, 2}, :mod_fun]}},
        default: [],
        doc:
          "A list of two-arity functions or tuples in the format `{module, function}` that serve as custom validators. The function will be given the key and value as arguments, and must return a list of string errors (or an empty list if no errors are present)."
      ),
    doc:
      Value.new(
        is: {:one_of, [:binary, {:=, false}]},
        default: false,
        doc: "Documentation for the option."
      )
  ]

  ################################
  # Types
  ################################

  defstruct schema: []

  ################################
  # Public API
  ################################

  @doc false
  @spec new(KeywordValidator.base_schema()) ::
          {:ok, struct()} | {:error, :invalid | {:invalid, key :: atom()}}
  def new(schema) do
    with {:ok, schema} <- validate_schema(schema, []) do
      {:ok, %__MODULE__{schema: schema}}
    end
  end

  @doc false
  @spec schema :: struct()
  def schema, do: %__MODULE__{schema: @opts_schema}

  ################################
  # Private API
  ################################

  defp validate_schema([], final), do: {:ok, Enum.reverse(final)}

  defp validate_schema([{key, opts} | keyword], final) do
    schema = schema()

    case KeywordValidator.validate(opts, schema) do
      {:ok, _} -> validate_schema(keyword, [{key, Value.new(opts)} | final])
      {:error, _invalid} -> {:error, {:invalid, key}}
    end
  end

  defp validate_schema(_, _) do
    {:error, :invalid}
  end

  defimpl Inspect do
    def inspect(schema, _) do
      keys = Enum.map(schema.schema, &elem(&1, 0))
      "#KeywordValidator.Schema<keys: #{inspect(keys)}>"
    end
  end
end
