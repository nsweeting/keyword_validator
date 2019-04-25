defmodule KeywordValidatorTest do
  use ExUnit.Case

  describe "validate/2" do
    test "will return the keyword when valid" do
      keyword = [foo: :foo, bar: :bar]
      schema = %{foo: [type: :atom], bar: []}

      assert {:ok, [foo: :foo, bar: :bar]} = KeywordValidator.validate(keyword, schema)
    end

    test "will return errors for extra keys" do
      keyword = [foo: :foo, bar: :bar, baz: :baz]
      schema = %{foo: []}

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_has_error(invalid, :bar, "is not a valid key")
      assert_has_error(invalid, :baz, "is not a valid key")
    end

    test "will return errors for required keys" do
      keyword = [foo: :foo, bar: nil, baz: nil]
      schema = %{foo: [required: true], bar: [required: true], baz: [required: true]}

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "is a required key")
      assert_has_error(invalid, :baz, "is a required key")
    end

    test "will do nothing for unrequired keys" do
      keyword = []
      schema = %{foo: [required: false]}

      assert {:ok, []} = KeywordValidator.validate(keyword, schema)

      keyword = []
      schema = %{foo: []}

      assert {:ok, []} = KeywordValidator.validate(keyword, schema)
    end

    test "will set the default for unrequired keys" do
      keyword = []
      schema = %{foo: [default: :foo, required: false]}

      assert {:ok, [foo: :foo]} = KeywordValidator.validate(keyword, schema)

      keyword = []
      schema = %{foo: [default: :foo]}

      assert {:ok, [foo: :foo]} = KeywordValidator.validate(keyword, schema)
    end

    test "will return errors for atom typed keys" do
      keyword = [foo: :foo, bar: 0, baz: "baz"]
      schema = %{foo: [type: :atom], bar: [type: :atom], baz: [type: :atom]}

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be an atom")
      assert_has_error(invalid, :baz, "must be an atom")
    end

    test "will return errors for binary typed keys" do
      keyword = [foo: "foo", bar: 0, baz: :baz]
      schema = %{foo: [type: :binary], bar: [type: :binary], baz: [type: :binary]}

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a binary")
      assert_has_error(invalid, :baz, "must be a binary")
    end

    test "will return errors for bitstring typed keys" do
      keyword = [foo: <<1::3>>, bar: 0, baz: :baz]
      schema = %{foo: [type: :bitstring], bar: [type: :bitstring], baz: [type: :bitstring]}

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a bitstring")
      assert_has_error(invalid, :baz, "must be a bitstring")
    end

    test "will return errors for boolean typed keys" do
      keyword = [foo: true, bar: 0, baz: :baz]
      schema = %{foo: [type: :boolean], bar: [type: :boolean], baz: [type: :boolean]}

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a boolean")
      assert_has_error(invalid, :baz, "must be a boolean")
    end

    test "will return errors for float typed keys" do
      keyword = [foo: 1.0, bar: 0, baz: :baz]
      schema = %{foo: [type: :float], bar: [type: :float], baz: [type: :float]}

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a float")
      assert_has_error(invalid, :baz, "must be a float")
    end

    test "will return errors for function typed keys" do
      keyword = [foo: fn -> nil end, bar: 0, baz: :baz]
      schema = %{foo: [type: :function], bar: [type: :function], baz: [type: :function]}

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a function")
      assert_has_error(invalid, :baz, "must be a function")
    end

    test "will return errors for function and arity typed keys" do
      keyword = [foo: fn _ -> nil end, bar: fn _, _ -> nil end, baz: :baz]

      schema = %{
        foo: [type: {:function, 1}],
        bar: [type: {:function, 1}],
        baz: [type: {:function, 1}]
      }

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a function of arity 1")
      assert_has_error(invalid, :baz, "must be a function of arity 1")
    end

    test "will return errors for integer typed keys" do
      keyword = [foo: 1, bar: :bar, baz: :baz]
      schema = %{foo: [type: :integer], bar: [type: :integer], baz: [type: :integer]}

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be an integer")
      assert_has_error(invalid, :baz, "must be an integer")
    end

    test "will return errors for list typed keys" do
      keyword = [foo: [], bar: 0, baz: :baz]
      schema = %{foo: [type: :list], bar: [type: :list], baz: [type: :list]}

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a list")
      assert_has_error(invalid, :baz, "must be a list")
    end

    test "will return errors for list and list value typed keys" do
      keyword = [foo: ["foo", "foo"], bar: [0, 1], baz: ["baz", :baz]]

      schema = %{
        foo: [type: {:list, :binary}],
        bar: [type: {:list, :atom}],
        baz: [type: {:list, :integer}]
      }

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a list of type :atom")
      assert_has_error(invalid, :baz, "must be a list of type :integer")
    end

    test "will return errors for map typed keys" do
      keyword = [foo: %{}, bar: 0, baz: :baz]
      schema = %{foo: [type: :map], bar: [type: :map], baz: [type: :map]}

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a map")
      assert_has_error(invalid, :baz, "must be a map")
    end

    test "will return errors for number typed keys" do
      keyword = [foo: 1, bar: "bar", baz: :baz]
      schema = %{foo: [type: :number], bar: [type: :number], baz: [type: :number]}

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a number")
      assert_has_error(invalid, :baz, "must be a number")
    end

    test "will return errors for pid typed keys" do
      keyword = [foo: self(), bar: 0, baz: :baz]
      schema = %{foo: [type: :pid], bar: [type: :pid], baz: [type: :pid]}

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a PID")
      assert_has_error(invalid, :baz, "must be a PID")
    end

    test "will return errors for port typed keys" do
      keyword = [foo: Port.open({:spawn, ""}, []), bar: 0, baz: :baz]
      schema = %{foo: [type: :port], bar: [type: :port], baz: [type: :port]}

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a port")
      assert_has_error(invalid, :baz, "must be a port")
    end

    test "will return errors for struct typed keys" do
      keyword = [foo: %MapSet{}, bar: 0, baz: :baz]
      schema = %{foo: [type: :struct], bar: [type: :struct], baz: [type: :struct]}

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a struct")
      assert_has_error(invalid, :baz, "must be a struct")
    end

    test "will return errors for struct and module typed keys" do
      keyword = [foo: %MapSet{}, bar: %MapSet{}, baz: %MapSet{}]

      schema = %{
        foo: [type: {:struct, MapSet}],
        bar: [type: {:struct, Bar}],
        baz: [type: {:struct, Baz}]
      }

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a struct of type Bar")
      assert_has_error(invalid, :baz, "must be a struct of type Baz")
    end

    test "will return errors for tuple typed keys" do
      keyword = [foo: {}, bar: 0, baz: :baz]
      schema = %{foo: [type: :tuple], bar: [type: :tuple], baz: [type: :tuple]}

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a tuple")
      assert_has_error(invalid, :baz, "must be a tuple")
    end

    test "will return errors for tuple sized typed keys" do
      keyword = [foo: {1}, bar: {}, baz: {}]
      schema = %{foo: [type: {:tuple, 1}], bar: [type: {:tuple, 1}], baz: [type: {:tuple, 1}]}

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be a tuple of size 1")
      assert_has_error(invalid, :baz, "must be a tuple of size 1")
    end

    test "will return errors for multiple types" do
      keyword = [foo: :foo, bar: 0, baz: :baz]

      schema = %{
        foo: [type: [:atom, :binary]],
        bar: [type: [:atom, :binary]],
        baz: [type: [:pid, :port]]
      }

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be one of the following: [:atom, :binary]")
      assert_has_error(invalid, :baz, "must be one of the following: [:pid, :port]")
    end

    test "will return errors for format" do
      keyword = [foo: "foo", bar: "bar", baz: "baz"]
      schema = %{foo: [format: ~r/foo/], bar: [format: ~r/baz/], baz: [format: ~r/bar/]}

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "has invalid format")
      assert_has_error(invalid, :baz, "has invalid format")
    end

    test "will return errors for inclusion" do
      keyword = [foo: :foo, bar: :bar, baz: :baz]
      schema = %{foo: [inclusion: [:foo]], bar: [inclusion: [:foo]], baz: [inclusion: [:foo]]}

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "must be one of: [:foo]")
      assert_has_error(invalid, :baz, "must be one of: [:foo]")
    end

    test "will return errors for custom functions" do
      good_validator = fn _key, _val ->
        []
      end

      bad_validator = fn _key, _val ->
        ["custom error"]
      end

      keyword = [foo: "foo", bar: "bar", baz: "baz"]

      schema = %{
        foo: [custom: [good_validator]],
        bar: [custom: [bad_validator]],
        baz: [custom: [bad_validator]]
      }

      assert {:error, invalid} = KeywordValidator.validate(keyword, schema)
      assert_no_error(invalid, :foo)
      assert_has_error(invalid, :bar, "custom error")
      assert_has_error(invalid, :baz, "custom error")
    end
  end

  describe "validate!/2" do
    test "will return the keyword when valid" do
      keyword = [foo: :foo, bar: :bar]
      schema = %{foo: [type: :atom], bar: []}

      assert [foo: :foo, bar: :bar] = KeywordValidator.validate!(keyword, schema)
    end

    test "will raise an ArguementError if invalid keys are found" do
      keyword = [foo: :foo]
      schema = %{foo: [type: :binary]}

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
