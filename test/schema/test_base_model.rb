# frozen_string_literal: true

require "test_helper"

class TestBaseModel < Minitest::Test
  def setup
    # Create a test subclass
    @klass = Class.new(AgentClientProtocol::Schema::BaseModel) do
      property :name, required: true
      property :age, type: Integer, default: 0
      property :is_admin, json_name: "isAdmin", default: false
      property :_meta, type: :hash, default: nil
    end
  end

  def test_constructor_with_required_fields
    obj = @klass.new(name: "Alice")
    assert_equal "Alice", obj.name
    assert_equal 0, obj.age
    assert_equal false, obj.is_admin
  end

  def test_to_h_uses_camel_case
    obj = @klass.new(name: "Alice", age: 30, is_admin: true)
    expected = {"name" => "Alice", "age" => 30, "isAdmin" => true}
    assert_equal expected, obj.to_h
  end

  def test_from_hash_with_camel_case_keys
    obj = @klass.from_hash({"name" => "Bob", "age" => 25, "isAdmin" => true})
    assert_equal "Bob", obj.name
    assert_equal 25, obj.age
    assert_equal true, obj.is_admin
  end

  def test_from_hash_with_snake_case_keys
    obj = @klass.from_hash({"name" => "Bob", "age" => 25, "is_admin" => true})
    assert_equal "Bob", obj.name
    assert_equal true, obj.is_admin
  end

  def test_roundtrip
    original = @klass.new(name: "Carol", age: 42, is_admin: true)
    restored = @klass.from_hash(original.to_h)
    assert_equal original, restored
  end

  def test_nil_values_omitted
    obj = @klass.new(name: "Dave")
    h = obj.to_h
    refute h.key?("_meta")
  end

  def test_meta_field_preserved
    obj = @klass.new(name: "Eve", _meta: {"custom" => "value"})
    assert_equal({"custom" => "value"}, obj._meta)
    assert_equal({"custom" => "value"}, obj.to_h["_meta"])
  end

  def test_equality
    a = @klass.new(name: "Alice", age: 30)
    b = @klass.new(name: "Alice", age: 30)
    assert_equal a, b
  end

  def test_inequality
    a = @klass.new(name: "Alice", age: 30)
    b = @klass.new(name: "Alice", age: 31)
    refute_equal a, b
  end

  def test_from_hash_returns_nil_for_nil
    assert_nil @klass.from_hash(nil)
  end

  def test_nested_model
    inner = Class.new(AgentClientProtocol::Schema::BaseModel) do
      property :value, required: true
    end

    outer = Class.new(AgentClientProtocol::Schema::BaseModel) do
      property :inner, type: inner, required: true
    end

    obj = outer.new(inner: inner.new(value: "hello"))
    h = obj.to_h
    assert_equal({"inner" => {"value" => "hello"}}, h)

    restored = outer.from_hash(h)
    assert_equal "hello", restored.inner.value
  end

  def test_array_of_models
    item = Class.new(AgentClientProtocol::Schema::BaseModel) do
      property :id, required: true
    end

    container = Class.new(AgentClientProtocol::Schema::BaseModel) do
      property :items, type: [:array, item], default: []
    end

    obj = container.new(items: [item.new(id: 1), item.new(id: 2)])
    h = obj.to_h
    assert_equal [{"id" => 1}, {"id" => 2}], h["items"]

    restored = container.from_hash(h)
    assert_equal 2, restored.items.size
    assert_equal 1, restored.items[0].id
  end

  def test_defaults_are_not_shared
    a = @klass.new(name: "A")
    b = @klass.new(name: "B")
    # Defaults should be independent copies
    assert_equal 0, a.age
    assert_equal 0, b.age
  end

  def test_inspect
    obj = @klass.new(name: "Alice")
    assert_includes obj.inspect, "name: \"Alice\""
  end
end
