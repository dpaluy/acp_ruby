# frozen_string_literal: true

require "test_helper"
require "stringio"

class TestNdjsonWriter < Minitest::Test
  def test_writes_json_with_newline
    io = StringIO.new
    writer = AgentClientProtocol::Transport::NdjsonWriter.new(io)
    writer.write({"hello" => "world"})
    assert_equal "{\"hello\":\"world\"}\n", io.string
  end

  def test_writes_multiple_messages
    io = StringIO.new
    writer = AgentClientProtocol::Transport::NdjsonWriter.new(io)
    writer.write({"a" => 1})
    writer.write({"b" => 2})
    lines = io.string.split("\n")
    assert_equal 2, lines.size
    assert_equal({"a" => 1}, JSON.parse(lines[0]))
    assert_equal({"b" => 2}, JSON.parse(lines[1]))
  end
end

class TestNdjsonReader < Minitest::Test
  def test_reads_json_lines
    io = StringIO.new("{\"a\":1}\n{\"b\":2}\n")
    reader = AgentClientProtocol::Transport::NdjsonReader.new(io)
    messages = reader.each.to_a
    assert_equal [{"a" => 1}, {"b" => 2}], messages
  end

  def test_skips_empty_lines
    io = StringIO.new("{\"a\":1}\n\n{\"b\":2}\n")
    reader = AgentClientProtocol::Transport::NdjsonReader.new(io)
    messages = reader.each.to_a
    assert_equal [{"a" => 1}, {"b" => 2}], messages
  end

  def test_raises_on_invalid_json
    io = StringIO.new("not json\n")
    reader = AgentClientProtocol::Transport::NdjsonReader.new(io)
    assert_raises(AgentClientProtocol::RequestError) { reader.each.to_a }
  end

  def test_handles_eof
    io = StringIO.new("")
    reader = AgentClientProtocol::Transport::NdjsonReader.new(io)
    assert_equal [], reader.each.to_a
  end
end
