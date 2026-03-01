# frozen_string_literal: true

# AUTO-GENERATED from schema.json — DO NOT EDIT

module AgentClientProtocol
  module Schema

    module PermissionOptionKind
      ALLOW_ONCE = "allow_once".freeze
      ALLOW_ALWAYS = "allow_always".freeze
      REJECT_ONCE = "reject_once".freeze
      REJECT_ALWAYS = "reject_always".freeze
      ALL = [ALLOW_ONCE, ALLOW_ALWAYS, REJECT_ONCE, REJECT_ALWAYS].freeze
    end

    module PlanEntryPriority
      HIGH = "high".freeze
      MEDIUM = "medium".freeze
      LOW = "low".freeze
      ALL = [HIGH, MEDIUM, LOW].freeze
    end

    module PlanEntryStatus
      PENDING = "pending".freeze
      IN_PROGRESS = "in_progress".freeze
      COMPLETED = "completed".freeze
      ALL = [PENDING, IN_PROGRESS, COMPLETED].freeze
    end

    module StopReason
      END_TURN = "end_turn".freeze
      MAX_TOKENS = "max_tokens".freeze
      MAX_TURN_REQUESTS = "max_turn_requests".freeze
      REFUSAL = "refusal".freeze
      CANCELLED = "cancelled".freeze
      ALL = [END_TURN, MAX_TOKENS, MAX_TURN_REQUESTS, REFUSAL, CANCELLED].freeze
    end

    module ToolCallStatus
      PENDING = "pending".freeze
      IN_PROGRESS = "in_progress".freeze
      COMPLETED = "completed".freeze
      FAILED = "failed".freeze
      ALL = [PENDING, IN_PROGRESS, COMPLETED, FAILED].freeze
    end

    module ToolKind
      READ = "read".freeze
      EDIT = "edit".freeze
      DELETE = "delete".freeze
      MOVE = "move".freeze
      SEARCH = "search".freeze
      EXECUTE = "execute".freeze
      THINK = "think".freeze
      FETCH = "fetch".freeze
      SWITCH_MODE = "switch_mode".freeze
      OTHER = "other".freeze
      ALL = [READ, EDIT, DELETE, MOVE, SEARCH, EXECUTE, THINK, FETCH, SWITCH_MODE, OTHER].freeze
    end

    module ContentBlock
      TEXT = "text".freeze
      IMAGE = "image".freeze
      AUDIO = "audio".freeze
      RESOURCE_LINK = "resource_link".freeze
      RESOURCE = "resource".freeze

      def self.parse(hash)
        return nil if hash.nil?
        disc = hash["type"]
        case disc
        when "text"
          obj = TextContent.from_hash(hash)
          obj
        when "image"
          obj = ImageContent.from_hash(hash)
          obj
        when "audio"
          obj = AudioContent.from_hash(hash)
          obj
        when "resource_link"
          obj = ResourceLink.from_hash(hash)
          obj
        when "resource"
          obj = EmbeddedResource.from_hash(hash)
          obj
        else
          hash
        end
      end
    end

    module RequestPermissionOutcome
      CANCELLED = "cancelled".freeze
      SELECTED = "selected".freeze

      def self.parse(hash)
        return nil if hash.nil?
        disc = hash["outcome"]
        case disc
        when "cancelled"
          hash
        when "selected"
          obj = SelectedPermissionOutcome.from_hash(hash)
          obj
        else
          hash
        end
      end
    end

    module SessionConfigOption
      SELECT = "select".freeze

      def self.parse(hash)
        return nil if hash.nil?
        disc = hash["type"]
        case disc
        when "select"
          obj = SessionConfigSelect.from_hash(hash)
          obj
        else
          hash
        end
      end
    end

    module SessionUpdate
      USER_MESSAGE_CHUNK = "user_message_chunk".freeze
      AGENT_MESSAGE_CHUNK = "agent_message_chunk".freeze
      AGENT_THOUGHT_CHUNK = "agent_thought_chunk".freeze
      TOOL_CALL = "tool_call".freeze
      TOOL_CALL_UPDATE = "tool_call_update".freeze
      PLAN = "plan".freeze
      AVAILABLE_COMMANDS_UPDATE = "available_commands_update".freeze
      CURRENT_MODE_UPDATE = "current_mode_update".freeze
      CONFIG_OPTION_UPDATE = "config_option_update".freeze

      def self.parse(hash)
        return nil if hash.nil?
        disc = hash["sessionUpdate"]
        case disc
        when "user_message_chunk"
          obj = ContentChunk.from_hash(hash)
          obj
        when "agent_message_chunk"
          obj = ContentChunk.from_hash(hash)
          obj
        when "agent_thought_chunk"
          obj = ContentChunk.from_hash(hash)
          obj
        when "tool_call"
          obj = ToolCall.from_hash(hash)
          obj
        when "tool_call_update"
          obj = ToolCallUpdate.from_hash(hash)
          obj
        when "plan"
          obj = Plan.from_hash(hash)
          obj
        when "available_commands_update"
          obj = AvailableCommandsUpdate.from_hash(hash)
          obj
        when "current_mode_update"
          obj = CurrentModeUpdate.from_hash(hash)
          obj
        when "config_option_update"
          obj = ConfigOptionUpdate.from_hash(hash)
          obj
        else
          hash
        end
      end
    end

    module ToolCallContent
      CONTENT = "content".freeze
      DIFF = "diff".freeze
      TERMINAL = "terminal".freeze

      def self.parse(hash)
        return nil if hash.nil?
        disc = hash["type"]
        case disc
        when "content"
          obj = Content.from_hash(hash)
          obj
        when "diff"
          obj = Diff.from_hash(hash)
          obj
        when "terminal"
          obj = Terminal.from_hash(hash)
          obj
        else
          hash
        end
      end
    end
  end
end
