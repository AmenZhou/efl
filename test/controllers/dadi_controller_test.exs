defmodule Efl.DadiControllerTest do
  use Efl.ConnCase

  describe "GET /dadi/scratch" do
    test "starts DADI processing when not running", %{conn: conn} do
      # Mock remote_ip to simulate localhost
      conn = %{conn | remote_ip: {127, 0, 0, 1}}
      
      # Ensure no process is running
      case Process.whereis(:dadi_processor) do
        nil -> :ok
        pid -> 
          Process.exit(pid, :kill)
          Process.unregister(:dadi_processor)
      end
      
      conn = get(conn, "/dadi/scratch")
      response = text_response(conn, 200)
      assert response =~ "started successfully"
    end

    test "returns already running message when process is active", %{conn: conn} do
      # Mock remote_ip to simulate localhost
      conn = %{conn | remote_ip: {127, 0, 0, 1}}
      
      # Start a process first
      case Process.whereis(:dadi_processor) do
        nil -> 
          {:ok, pid} = Task.start_link(fn -> 
            Process.register(self(), :dadi_processor)
            :timer.sleep(1000) # Keep process alive for test
          end)
          :ok
        _pid -> :ok
      end
      
      # Try to start again
      conn = get(conn, "/dadi/scratch")
      response = text_response(conn, 200)
      assert response =~ "already in progress"
      
      # Clean up
      case Process.whereis(:dadi_processor) do
        nil -> :ok
        pid -> 
          Process.exit(pid, :kill)
          Process.unregister(:dadi_processor)
      end
    end
  end

  describe "GET /dadi/status" do
    test "returns running status when process is active", %{conn: conn} do
      # Mock remote_ip to simulate localhost
      conn = %{conn | remote_ip: {127, 0, 0, 1}}
      
      # Start a process
      {:ok, pid} = Task.start_link(fn -> 
        Process.register(self(), :dadi_processor)
        :timer.sleep(1000) # Keep process alive for test
      end)
      
      conn = get(conn, "/dadi/status")
      response = text_response(conn, 200)
      assert response =~ "Running"
      
      # Clean up
      Process.exit(pid, :kill)
      Process.unregister(:dadi_processor)
    end

    test "returns not running when no process is active", %{conn: conn} do
      # Mock remote_ip to simulate localhost
      conn = %{conn | remote_ip: {127, 0, 0, 1}}
      
      # Ensure no process is running
      case Process.whereis(:dadi_processor) do
        nil -> :ok
        pid -> 
          Process.exit(pid, :kill)
          Process.unregister(:dadi_processor)
      end
      
      conn = get(conn, "/dadi/status")
      response = text_response(conn, 200)
      assert response =~ "Not running"
    end
  end

  describe "GET /dadi/stop" do
    test "stops running process", %{conn: conn} do
      # Mock remote_ip to simulate localhost
      conn = %{conn | remote_ip: {127, 0, 0, 1}}
      
      # Start a process
      {:ok, pid} = Task.start_link(fn -> 
        Process.register(self(), :dadi_processor)
        :timer.sleep(1000) # Keep process alive for test
      end)
      
      conn = get(conn, "/dadi/stop")
      response = text_response(conn, 200)
      assert response =~ "stopped successfully"
      
      # Verify process is no longer registered
      assert Process.whereis(:dadi_processor) == nil
    end

    test "returns not running when no process to stop", %{conn: conn} do
      # Mock remote_ip to simulate localhost
      conn = %{conn | remote_ip: {127, 0, 0, 1}}
      
      # Ensure no process is running
      case Process.whereis(:dadi_processor) do
        nil -> :ok
        pid -> 
          Process.exit(pid, :kill)
          Process.unregister(:dadi_processor)
      end
      
      conn = get(conn, "/dadi/stop")
      assert text_response(conn, 200) =~ "DADI processing: Not running"
    end
  end
end