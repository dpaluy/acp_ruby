# frozen_string_literal: true

# AUTO-GENERATED from schema.json — DO NOT EDIT

require_relative "base_model"
require_relative "types"

module AgentClientProtocol
  module Schema

    class McpCapabilities < BaseModel
      property :_meta, type: :hash, default: nil
      property :http, default: false
      property :sse, default: false
    end

    class PromptCapabilities < BaseModel
      property :_meta, type: :hash, default: nil
      property :audio, default: false
      property :embedded_context, default: false
      property :image, default: false
    end

    class SessionCapabilities < BaseModel
      property :_meta, type: :hash, default: nil
    end

    class AgentCapabilities < BaseModel
      property :_meta, type: :hash, default: nil
      property :load_session, default: false
      property :mcp_capabilities, type: McpCapabilities, default: {"http" => false, "sse" => false}
      property :prompt_capabilities, type: PromptCapabilities, default: {"audio" => false, "embeddedContext" => false, "image" => false}
      property :session_capabilities, type: SessionCapabilities, default: {}
    end

    class Annotations < BaseModel
      property :_meta, type: :hash, default: nil
      property :audience
      property :last_modified
      property :priority
    end

    class AudioContent < BaseModel
      discriminator "type", "audio"
      property :_meta, type: :hash, default: nil
      property :annotations, type: Annotations, default: nil
      property :data, required: true
      property :mime_type, required: true
    end

    class AuthMethod < BaseModel
      property :_meta, type: :hash, default: nil
      property :description
      property :id, required: true
      property :name, required: true
    end

    class AuthenticateRequest < BaseModel
      property :_meta, type: :hash, default: nil
      property :method_id, required: true
    end

    class AuthenticateResponse < BaseModel
      property :_meta, type: :hash, default: nil
    end

    class AvailableCommand < BaseModel
      property :_meta, type: :hash, default: nil
      property :description, required: true
      property :input, default: nil
      property :name, required: true
    end

    class AvailableCommandsUpdate < BaseModel
      discriminator "sessionUpdate", "available_commands_update"
      property :_meta, type: :hash, default: nil
      property :available_commands, type: [:array, AvailableCommand], required: true
    end

    class BlobResourceContents < BaseModel
      property :_meta, type: :hash, default: nil
      property :blob, required: true
      property :mime_type
      property :uri, required: true
    end

    class CancelNotification < BaseModel
      property :_meta, type: :hash, default: nil
      property :session_id, required: true
    end

    class FileSystemCapability < BaseModel
      property :_meta, type: :hash, default: nil
      property :read_text_file, default: false
      property :write_text_file, default: false
    end

    class ClientCapabilities < BaseModel
      property :_meta, type: :hash, default: nil
      property :fs, type: FileSystemCapability, default: {"readTextFile" => false, "writeTextFile" => false}
      property :terminal, default: false
    end

    class ConfigOptionUpdate < BaseModel
      discriminator "sessionUpdate", "config_option_update"
      property :_meta, type: :hash, default: nil
      property :config_options, type: [:array, SessionConfigOption], required: true
    end

    class Content < BaseModel
      discriminator "type", "content"
      property :_meta, type: :hash, default: nil
      property :content, type: :content_block, required: true
    end

    class ContentChunk < BaseModel
      property :_meta, type: :hash, default: nil
      property :content, type: :content_block, required: true
    end

    class EnvVariable < BaseModel
      property :_meta, type: :hash, default: nil
      property :name, required: true
      property :value, required: true
    end

    class CreateTerminalRequest < BaseModel
      property :_meta, type: :hash, default: nil
      property :args
      property :command, required: true
      property :cwd
      property :env, type: [:array, EnvVariable]
      property :output_byte_limit
      property :session_id, required: true
    end

    class CreateTerminalResponse < BaseModel
      property :_meta, type: :hash, default: nil
      property :terminal_id, required: true
    end

    class CurrentModeUpdate < BaseModel
      discriminator "sessionUpdate", "current_mode_update"
      property :_meta, type: :hash, default: nil
      property :current_mode_id, required: true
    end

    class Diff < BaseModel
      discriminator "type", "diff"
      property :_meta, type: :hash, default: nil
      property :new_text, required: true
      property :old_text
      property :path, required: true
    end

    class EmbeddedResource < BaseModel
      discriminator "type", "resource"
      property :_meta, type: :hash, default: nil
      property :annotations, type: Annotations, default: nil
      property :resource, required: true
    end

    class Error < BaseModel
      property :code, required: true
      property :data
      property :message, required: true
    end

    class HttpHeader < BaseModel
      property :_meta, type: :hash, default: nil
      property :name, required: true
      property :value, required: true
    end

    class ImageContent < BaseModel
      discriminator "type", "image"
      property :_meta, type: :hash, default: nil
      property :annotations, type: Annotations, default: nil
      property :data, required: true
      property :mime_type, required: true
      property :uri
    end

    class Implementation < BaseModel
      property :_meta, type: :hash, default: nil
      property :name, required: true
      property :title
      property :version, required: true
    end

    class InitializeRequest < BaseModel
      property :_meta, type: :hash, default: nil
      property :client_capabilities, type: ClientCapabilities, default: {"fs" => {"readTextFile" => false, "writeTextFile" => false}, "terminal" => false}
      property :client_info, type: Implementation, default: nil
      property :protocol_version, required: true
    end

    class InitializeResponse < BaseModel
      property :_meta, type: :hash, default: nil
      property :agent_capabilities, type: AgentCapabilities, default: {"loadSession" => false, "mcpCapabilities" => {"http" => false, "sse" => false}, "promptCapabilities" => {"audio" => false, "embeddedContext" => false, "image" => false}, "sessionCapabilities" => {}}
      property :agent_info, type: Implementation, default: nil
      property :auth_methods, type: [:array, AuthMethod], default: []
      property :protocol_version, required: true
    end

    class KillTerminalCommandRequest < BaseModel
      property :_meta, type: :hash, default: nil
      property :session_id, required: true
      property :terminal_id, required: true
    end

    class KillTerminalCommandResponse < BaseModel
      property :_meta, type: :hash, default: nil
    end

    class LoadSessionRequest < BaseModel
      property :_meta, type: :hash, default: nil
      property :cwd, required: true
      property :mcp_servers, required: true
      property :session_id, required: true
    end

    class SessionMode < BaseModel
      property :_meta, type: :hash, default: nil
      property :description
      property :id, required: true
      property :name, required: true
    end

    class SessionModeState < BaseModel
      property :_meta, type: :hash, default: nil
      property :available_modes, type: [:array, SessionMode], required: true
      property :current_mode_id, required: true
    end

    class LoadSessionResponse < BaseModel
      property :_meta, type: :hash, default: nil
      property :config_options, type: [:array, SessionConfigOption]
      property :modes, type: SessionModeState, default: nil
    end

    class McpServerHttp < BaseModel
      property :_meta, type: :hash, default: nil
      property :headers, type: [:array, HttpHeader], required: true
      property :name, required: true
      property :url, required: true
    end

    class McpServerSse < BaseModel
      property :_meta, type: :hash, default: nil
      property :headers, type: [:array, HttpHeader], required: true
      property :name, required: true
      property :url, required: true
    end

    class McpServerStdio < BaseModel
      property :_meta, type: :hash, default: nil
      property :args, required: true
      property :command, required: true
      property :env, type: [:array, EnvVariable], required: true
      property :name, required: true
    end

    class NewSessionRequest < BaseModel
      property :_meta, type: :hash, default: nil
      property :cwd, required: true
      property :mcp_servers, required: true
    end

    class NewSessionResponse < BaseModel
      property :_meta, type: :hash, default: nil
      property :config_options, type: [:array, SessionConfigOption]
      property :modes, type: SessionModeState, default: nil
      property :session_id, required: true
    end

    class PermissionOption < BaseModel
      property :_meta, type: :hash, default: nil
      property :kind, required: true
      property :name, required: true
      property :option_id, required: true
    end

    class PlanEntry < BaseModel
      property :_meta, type: :hash, default: nil
      property :content, required: true
      property :priority, required: true
      property :status, required: true
    end

    class Plan < BaseModel
      discriminator "sessionUpdate", "plan"
      property :_meta, type: :hash, default: nil
      property :entries, type: [:array, PlanEntry], required: true
    end

    class PromptRequest < BaseModel
      property :_meta, type: :hash, default: nil
      property :prompt, type: [:array, :content_block], required: true
      property :session_id, required: true
    end

    class PromptResponse < BaseModel
      property :_meta, type: :hash, default: nil
      property :stop_reason, required: true
    end

    class ReadTextFileRequest < BaseModel
      property :_meta, type: :hash, default: nil
      property :limit
      property :line
      property :path, required: true
      property :session_id, required: true
    end

    class ReadTextFileResponse < BaseModel
      property :_meta, type: :hash, default: nil
      property :content, required: true
    end

    class ReleaseTerminalRequest < BaseModel
      property :_meta, type: :hash, default: nil
      property :session_id, required: true
      property :terminal_id, required: true
    end

    class ReleaseTerminalResponse < BaseModel
      property :_meta, type: :hash, default: nil
    end

    class ToolCallLocation < BaseModel
      property :_meta, type: :hash, default: nil
      property :line
      property :path, required: true
    end

    class ToolCallUpdate < BaseModel
      discriminator "sessionUpdate", "tool_call_update"
      property :_meta, type: :hash, default: nil
      property :content, type: [:array, :tool_call_content]
      property :kind, default: nil
      property :locations, type: [:array, ToolCallLocation]
      property :raw_input
      property :raw_output
      property :status, default: nil
      property :title
      property :tool_call_id, required: true
    end

    class RequestPermissionRequest < BaseModel
      property :_meta, type: :hash, default: nil
      property :options, type: [:array, PermissionOption], required: true
      property :session_id, required: true
      property :tool_call, type: ToolCallUpdate, required: true
    end

    class RequestPermissionResponse < BaseModel
      property :_meta, type: :hash, default: nil
      property :outcome, type: :permission_outcome, required: true
    end

    class ResourceLink < BaseModel
      discriminator "type", "resource_link"
      property :_meta, type: :hash, default: nil
      property :annotations, type: Annotations, default: nil
      property :description
      property :mime_type
      property :name, required: true
      property :size
      property :title
      property :uri, required: true
    end

    class SelectedPermissionOutcome < BaseModel
      discriminator "outcome", "selected"
      property :_meta, type: :hash, default: nil
      property :option_id, required: true
    end

    class SessionConfigSelect < BaseModel
      discriminator "type", "select"
      property :current_value, required: true
      property :options, required: true
    end

    class SessionConfigSelectOption < BaseModel
      property :_meta, type: :hash, default: nil
      property :description
      property :name, required: true
      property :value, required: true
    end

    class SessionConfigSelectGroup < BaseModel
      property :_meta, type: :hash, default: nil
      property :group, required: true
      property :name, required: true
      property :options, type: [:array, SessionConfigSelectOption], required: true
    end

    class SessionNotification < BaseModel
      property :_meta, type: :hash, default: nil
      property :session_id, required: true
      property :update, type: :session_update, required: true
    end

    class SetSessionConfigOptionRequest < BaseModel
      property :_meta, type: :hash, default: nil
      property :config_id, required: true
      property :session_id, required: true
      property :value, required: true
    end

    class SetSessionConfigOptionResponse < BaseModel
      property :_meta, type: :hash, default: nil
      property :config_options, type: [:array, SessionConfigOption], required: true
    end

    class SetSessionModeRequest < BaseModel
      property :_meta, type: :hash, default: nil
      property :mode_id, required: true
      property :session_id, required: true
    end

    class SetSessionModeResponse < BaseModel
      property :_meta, type: :hash, default: nil
    end

    class Terminal < BaseModel
      discriminator "type", "terminal"
      property :_meta, type: :hash, default: nil
      property :terminal_id, required: true
    end

    class TerminalExitStatus < BaseModel
      property :_meta, type: :hash, default: nil
      property :exit_code
      property :signal
    end

    class TerminalOutputRequest < BaseModel
      property :_meta, type: :hash, default: nil
      property :session_id, required: true
      property :terminal_id, required: true
    end

    class TerminalOutputResponse < BaseModel
      property :_meta, type: :hash, default: nil
      property :exit_status, type: TerminalExitStatus, default: nil
      property :output, required: true
      property :truncated, required: true
    end

    class TextContent < BaseModel
      discriminator "type", "text"
      property :_meta, type: :hash, default: nil
      property :annotations, type: Annotations, default: nil
      property :text, required: true
    end

    class TextResourceContents < BaseModel
      property :_meta, type: :hash, default: nil
      property :mime_type
      property :text, required: true
      property :uri, required: true
    end

    class ToolCall < BaseModel
      discriminator "sessionUpdate", "tool_call"
      property :_meta, type: :hash, default: nil
      property :content, type: [:array, :tool_call_content]
      property :kind
      property :locations, type: [:array, ToolCallLocation]
      property :raw_input
      property :raw_output
      property :status
      property :title, required: true
      property :tool_call_id, required: true
    end

    class UnstructuredCommandInput < BaseModel
      property :_meta, type: :hash, default: nil
      property :hint, required: true
    end

    class WaitForTerminalExitRequest < BaseModel
      property :_meta, type: :hash, default: nil
      property :session_id, required: true
      property :terminal_id, required: true
    end

    class WaitForTerminalExitResponse < BaseModel
      property :_meta, type: :hash, default: nil
      property :exit_code
      property :signal
    end

    class WriteTextFileRequest < BaseModel
      property :_meta, type: :hash, default: nil
      property :content, required: true
      property :path, required: true
      property :session_id, required: true
    end

    class WriteTextFileResponse < BaseModel
      property :_meta, type: :hash, default: nil
    end
  end
end
