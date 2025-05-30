defmodule KeywordValidatorTest do
  use ExUnit.Case

  describe "validate/2" do
    test "will return the keyword when valid" do
      keyword = [foo: :foo, bar: :bar]
      schema = [foo: [is: :atom], bar: []]

      assert {:ok, [foo: :foo, bar: :bar]} = KeywordValidator.validate(keyword, schema)
    end

    test "will return errors for extra keys" do
      keyword = [foo: :foo, bar: :bar, baz: :baz]
      schema = [foo: []]

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_has_error(invalid, :bar, "is not a valid key")
      assert_has_error(invalid, :baz, "is not a valid key")
    end

    test "will not return errors for extra keys when not strict" do
      keyword = [bar: :bar]
      schema = [foo: []]

      assert {:ok, []} = KeywordValidator.validate(keyword, schema, strict: false)
    end

    test "will return errors for extra keys when strict" do
      keyword = [bar: :bar]
      schema = [foo: []]

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema, strict: true)
      assert_has_error(invalid, :bar, "is not a valid key")
    end

    test "will return errors for required keys" do
      keyword = [foo: :foo, bar: nil, baz: nil]
      schema = [foo: [required: true], bar: [required: true], baz: [required: true]]

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "is a required key")
      assert_has_error(invalid, :baz, "is a required key")
    end

    test "will do nothing for unrequired keys" do
      keyword = []
      schema = [foo: [required: false]]

      assert {:ok, []} = KeywordValidator.validate(keyword, schema)

      keyword = []
      schema = [foo: []]

      assert {:ok, []} = KeywordValidator.validate(keyword, schema)
    end

    test "will set the default for unrequired keys" do
      keyword = []
      schema = [foo: [default: :foo, required: false]]

      assert {:ok, [foo: :foo]} = KeywordValidator.validate(keyword, schema)

      keyword = []
      schema = [foo: [default: :foo]]

      assert {:ok, [foo: :foo]} = KeywordValidator.validate(keyword, schema)
    end

    test "will set false defaults" do
      keyword = []
      schema = [foo: [default: false]]

      assert {:ok, [foo: false]} = KeywordValidator.validate(keyword, schema)
    end

    test "will return errors for atom typed keys" do
      keyword = [foo: :foo, bar: 0, baz: "baz"]
      schema = [foo: [is: :atom], bar: [is: :atom], baz: [is: :atom]]

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be an atom")
      assert_has_error(invalid, :baz, "must be an atom")
    end

    test "will return errors for atom choice typed keys" do
      keyword = [foo: :foo, bar: :bar]
      schema = [foo: [is: {:atom, [:foo]}], bar: [is: {:atom, [:foo]}]]

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be one of: [:foo]")
    end

    test "will return errors for binary typed keys" do
      keyword = [foo: "foo", bar: 0, baz: :baz]
      schema = [foo: [is: :binary], bar: [is: :binary], baz: [is: :binary]]

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a binary")
      assert_has_error(invalid, :baz, "must be a binary")
    end

    test "will return errors for bitstring typed keys" do
      keyword = [foo: <<1::3>>, bar: 0, baz: :baz]
      schema = [foo: [is: :bitstring], bar: [is: :bitstring], baz: [is: :bitstring]]

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a bitstring")
      assert_has_error(invalid, :baz, "must be a bitstring")
    end

    test "will return errors for boolean typed keys" do
      keyword = [foo: true, bar: 0, baz: :baz]
      schema = [foo: [is: :boolean], bar: [is: :boolean], baz: [is: :boolean]]

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a boolean")
      assert_has_error(invalid, :baz, "must be a boolean")
    end

    test "will return errors for float typed keys" do
      keyword = [foo: 1.0, bar: 0, baz: :baz]
      schema = [foo: [is: :float], bar: [is: :float], baz: [is: :float]]

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a float")
      assert_has_error(invalid, :baz, "must be a float")
    end

    test "will return errors for function typed keys" do
      keyword = [foo: fn -> nil end, bar: 0, baz: :baz]
      schema = [foo: [is: :fun], bar: [is: :fun], baz: [is: :fun]]

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a function")
      assert_has_error(invalid, :baz, "must be a function")
    end

    test "will return errors for function and arity typed keys" do
      keyword = [foo: fn _ -> nil end, bar: fn _, _ -> nil end, baz: :baz]

      schema = [
        foo: [is: {:fun, 1}],
        bar: [is: {:fun, 1}],
        baz: [is: {:fun, 1}]
      ]

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a function of arity 1")
      assert_has_error(invalid, :baz, "must be a function of arity 1")
    end

    test "will return errors for integer typed keys" do
      keyword = [foo: 1, bar: :bar, baz: :baz]
      schema = [foo: [is: :integer], bar: [is: :integer], baz: [is: :integer]]

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be an integer")
      assert_has_error(invalid, :baz, "must be an integer")
    end

    test "will return errors for keyword and schema typed keys" do
      keyword = [foo: [foo: :foo], bar: :bar, baz: [baz: :baz]]

      schema = [
        foo: [is: {:keyword, [foo: [is: :atom]]}],
        bar: [is: {:keyword, [foo: [is: :atom]]}],
        baz: [is: {:keyword, [baz: [is: :integer]]}]
      ]

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a keyword with structure: [foo: [is: :atom]]")
      assert_has_error(invalid, :baz, "must be a keyword with structure: [baz: [is: :integer]]")
    end

    test "will use defaults for lists of keyword and schema typed keys" do
      keyword = [foo: [[foo: :foo]]]

      schema = [
        foo: [is: {:list, {:keyword, [foo: [is: :atom], bar: [is: :atom, default: :bar]]}}]
      ]

      assert {:ok, [foo: [[foo: :foo, bar: :bar]]]} = KeywordValidator.validate(keyword, schema)
    end

    test "will use defaults for keyword and schema typed keys" do
      keyword = [foo: [foo: :foo]]

      schema = [
        foo: [is: {:keyword, [foo: [is: :atom], bar: [is: :atom, default: :bar]]}]
      ]

      assert {:ok, [foo: [foo: :foo, bar: :bar]]} = KeywordValidator.validate(keyword, schema)
    end

    test "will return errors for list typed keys" do
      keyword = [foo: [], bar: 0, baz: :baz]
      schema = [foo: [is: :list], bar: [is: :list], baz: [is: :list]]

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a list")
      assert_has_error(invalid, :baz, "must be a list")
    end

    test "will return errors for list and list value typed keys" do
      keyword = [foo: ["foo", "foo"], bar: [0, 1], baz: ["baz", :baz]]

      schema = [
        foo: [is: {:list, :binary}],
        bar: [is: {:list, :atom}],
        baz: [is: {:list, :integer}]
      ]

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a list of type :atom")
      assert_has_error(invalid, :baz, "must be a list of type :integer")
    end

    test "will return errors for map typed keys" do
      keyword = [foo: %{}, bar: 0, baz: :baz]
      schema = [foo: [is: :map], bar: [is: :map], baz: [is: :map]]

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a map")
      assert_has_error(invalid, :baz, "must be a map")
    end

    test "will return errors for mfa typed keys" do
      keyword = [foo: {String, :to_atom, ["foo"]}, bar: 0, baz: :baz]
      schema = [foo: [is: :mfa], bar: [is: :mfa], baz: [is: :mfa]]

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a mfa")
      assert_has_error(invalid, :baz, "must be a mfa")
    end

    test "will return errors for module typed keys" do
      keyword = [foo: __MODULE__, bar: 0, baz: "baz"]
      schema = [foo: [is: :mod], bar: [is: :mod], baz: [is: :mod]]

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a module")
      assert_has_error(invalid, :baz, "must be a module")
    end

    test "will return errors for number typed keys" do
      keyword = [foo: 1, bar: "bar", baz: :baz]
      schema = [foo: [is: :number], bar: [is: :number], baz: [is: :number]]

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a number")
      assert_has_error(invalid, :baz, "must be a number")
    end

    test "will return errors for pid typed keys" do
      keyword = [foo: self(), bar: 0, baz: :baz]
      schema = [foo: [is: :pid], bar: [is: :pid], baz: [is: :pid]]

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a PID")
      assert_has_error(invalid, :baz, "must be a PID")
    end

    test "will return errors for port typed keys" do
      keyword = [foo: Port.open({:spawn, ""}, []), bar: 0, baz: :baz]
      schema = [foo: [is: :port], bar: [is: :port], baz: [is: :port]]

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a port")
      assert_has_error(invalid, :baz, "must be a port")
    end

    test "will return errors for struct typed keys" do
      keyword = [foo: %MapSet{}, bar: 0, baz: :baz]
      schema = [foo: [is: :struct], bar: [is: :struct], baz: [is: :struct]]

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a struct")
      assert_has_error(invalid, :baz, "must be a struct")
    end

    test "will return errors for struct and module typed keys" do
      keyword = [foo: %MapSet{}, bar: %MapSet{}, baz: %MapSet{}]

      schema = [
        foo: [is: {:struct, MapSet}],
        bar: [is: {:struct, Date}],
        baz: [is: {:struct, Time}]
      ]

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a struct of type Date")
      assert_has_error(invalid, :baz, "must be a struct of type Time")
    end

    test "will return errors for tuple typed keys" do
      keyword = [foo: {}, bar: 0, baz: :baz]
      schema = [foo: [is: :tuple], bar: [is: :tuple], baz: [is: :tuple]]

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a tuple")
      assert_has_error(invalid, :baz, "must be a tuple")
    end

    test "will return errors for tuple sized typed keys" do
      keyword = [foo: {1}, bar: {}, baz: {}]
      schema = [foo: [is: {:tuple, 1}], bar: [is: {:tuple, 1}], baz: [is: {:tuple, 1}]]

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a tuple of size 1")
      assert_has_error(invalid, :baz, "must be a tuple of size 1")
    end

    test "will return errors for tuple structure typed keys" do
      keyword = [foo: {:foo, 1}, bar: {}, baz: {"baz", :baz}]

      schema = [
        foo: [is: {:tuple, {:atom, :integer}}],
        bar: [is: {:tuple, {:atom}}],
        baz: [is: {:tuple, {:atom, :binary}}]
      ]

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a tuple with the structure: {:atom}")
      assert_has_error(invalid, :baz, "must be a tuple with the structure: {:atom, :binary}")
    end

    test "will return errors for multiple types" do
      keyword = [foo: :foo, bar: 0, baz: :baz]

      schema = [
        foo: [is: {:one_of, [:atom, :binary]}],
        bar: [is: {:one_of, [:atom, :binary]}],
        baz: [is: {:one_of, [:pid, :port]}]
      ]

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be one of the following: [:atom, :binary]")
      assert_has_error(invalid, :baz, "must be one of the following: [:pid, :port]")
    end

    test "will return errors for custom functions" do
      good_validator = fn _key, _val ->
        []
      end

      bad_validator = fn _key, _val ->
        ["custom error"]
      end

      keyword = [foo: "foo", bar: "bar", baz: "baz"]

      schema = [
        foo: [custom: [good_validator]],
        bar: [custom: [bad_validator]],
        baz: [custom: [bad_validator]]
      ]

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "custom error")
      assert_has_error(invalid, :baz, "custom error")
    end

    test "will return errors for custom module functions" do
      defmodule Validator do
        def run(:foo, _val) do
          []
        end

        def run(_, _) do
          ["custom error"]
        end
      end

      keyword = [foo: "foo", bar: "bar", baz: "baz"]

      schema = [
        foo: [custom: [{Validator, :run}]],
        bar: [custom: [{Validator, :run}]],
        baz: [custom: [{Validator, :run}]]
      ]

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "custom error")
      assert_has_error(invalid, :baz, "custom error")
    end
  end

  describe "validate!/2" do
    test "will return the keyword when valid" do
      keyword = [foo: :foo, bar: :bar]
      schema = [foo: [is: :atom], bar: []]

      assert [foo: :foo, bar: :bar] = KeywordValidator.validate!(keyword, schema)
    end

    test "will raise an ArgumentError if invalid keys are found" do
      keyword = [foo: :foo]
      schema = [foo: [is: :binary]]

      assert_raise ArgumentError, fn ->
        KeywordValidator.validate!(keyword, schema)
      end
    end
  end

  def assert_has_error(invalid, key, msg) do
    errors = Keyword.get(invalid, key, [])
    assert Enum.member?(errors, msg)
  end

  def assert_no_error(invalid, key) do
    assert Keyword.get(invalid, key) == nil
  end
end
