# frozen_string_literal: true

require "async"

module AgentClientProtocol
  module Stdio
    SHUTDOWN_TIMEOUT = 5 # seconds

    module_function

    def run_agent(agent)
      Async do
        reader = Transport::NdjsonReader.new($stdin)
        writer = Transport::NdjsonWriter.new($stdout)

        # Redirect any puts/print to stderr so stdout is reserved for protocol
        $stdout = $stderr

        conn = Agent::Connection.new(agent, reader, writer)
        conn.listen
      end
    end

    def spawn_agent_process(client, command, *args, env: nil, cwd: nil)
      Async do |task|
        pid, stdin_w, stdout_r = spawn_process(command, *args, env: env, cwd: cwd)

        reader = Transport::NdjsonReader.new(stdout_r)
        writer = Transport::NdjsonWriter.new(stdin_w)
        conn = Client::Connection.new(client, reader, writer)

        listen_task = task.async { conn.listen }

        if block_given?
          begin
            yield conn, pid
          ensure
            shutdown_process(conn, pid, stdin_w, listen_task)
          end
        else
          [conn, pid, listen_task]
        end
      end
    end

    def spawn_client_process(agent, command, *args, env: nil, cwd: nil)
      Async do |task|
        pid, stdin_w, stdout_r = spawn_process(command, *args, env: env, cwd: cwd)

        reader = Transport::NdjsonReader.new(stdout_r)
        writer = Transport::NdjsonWriter.new(stdin_w)
        conn = Agent::Connection.new(agent, reader, writer)

        listen_task = task.async { conn.listen }

        if block_given?
          begin
            yield conn, pid
          ensure
            shutdown_process(conn, pid, stdin_w, listen_task)
          end
        else
          [conn, pid, listen_task]
        end
      end
    end

    def spawn_process(command, *args, env: nil, cwd: nil)
      spawn_env = clean_environment(env)
      opts = {in: :pipe, out: :pipe, err: $stderr}
      opts[:chdir] = cwd if cwd

      stdin_r, stdin_w = IO.pipe
      stdout_r, stdout_w = IO.pipe

      pid = Process.spawn(spawn_env, command, *args, in: stdin_r, out: stdout_w, err: $stderr, **(cwd ? {chdir: cwd} : {}))

      stdin_r.close
      stdout_w.close

      [pid, stdin_w, stdout_r]
    end

    def shutdown_process(conn, pid, stdin_w, listen_task)
      listen_task&.stop
      conn.close

      # Close stdin to signal the subprocess
      stdin_w.close unless stdin_w.closed?

      # Use a thread for waitpid to avoid blocking the async reactor
      reap_thread = Thread.new do
        begin
          Process.waitpid(pid)
        rescue Errno::ECHILD, Errno::ESRCH
          # Already reaped
        end
      end

      unless reap_thread.join(SHUTDOWN_TIMEOUT)
        begin
          Process.kill("TERM", pid)
        rescue Errno::ESRCH
          # Already gone
        end
        unless reap_thread.join(SHUTDOWN_TIMEOUT)
          begin
            Process.kill("KILL", pid)
          rescue Errno::ESRCH
            # Already gone
          end
          reap_thread.join(1)
        end
      end
    rescue Errno::ECHILD, Errno::ESRCH
      # Process already gone
    end

    def clean_environment(extra = nil)
      env = {}
      # Minimal safe environment
      %w[PATH HOME USER LANG TERM].each do |key|
        env[key] = ENV[key] if ENV[key]
      end
      env.merge!(extra) if extra
      env
    end
  end
end
