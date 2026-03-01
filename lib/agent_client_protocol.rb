# frozen_string_literal: true

require_relative "agent_client_protocol/version"
require_relative "agent_client_protocol/meta"

module AgentClientProtocol
  autoload :RequestError, "agent_client_protocol/error"
  autoload :Transport, "agent_client_protocol/transport"
  autoload :Connection, "agent_client_protocol/connection"
  autoload :Router, "agent_client_protocol/router"
  autoload :AgentInterface, "agent_client_protocol/agent"
  autoload :ClientInterface, "agent_client_protocol/client"
  autoload :Helpers, "agent_client_protocol/helpers"

  module Schema
    autoload :BaseModel, "agent_client_protocol/schema/base_model"
  end

  # Load generated schema types
  require_relative "agent_client_protocol/schema/generated"

  module Agent
    autoload :Connection, "agent_client_protocol/agent/connection"
    autoload :Router, "agent_client_protocol/agent/router"
  end

  module Client
    autoload :Connection, "agent_client_protocol/client/connection"
    autoload :Router, "agent_client_protocol/client/router"
  end

  module Contrib
    autoload :SessionAccumulator, "agent_client_protocol/contrib/session_accumulator"
    autoload :ToolCallTracker, "agent_client_protocol/contrib/tool_call_tracker"
    autoload :PermissionBroker, "agent_client_protocol/contrib/permission_broker"
  end

  module_function

  def run_agent(agent)
    require_relative "agent_client_protocol/stdio"
    Stdio.run_agent(agent)
  end

  def spawn_agent_process(client, command, *args, **opts, &block)
    require_relative "agent_client_protocol/stdio"
    Stdio.spawn_agent_process(client, command, *args, **opts, &block)
  end

  def spawn_client_process(agent, command, *args, **opts, &block)
    require_relative "agent_client_protocol/stdio"
    Stdio.spawn_client_process(agent, command, *args, **opts, &block)
  end
end
