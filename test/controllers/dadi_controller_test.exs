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

      # Start a process first using the real Dadi.start function
      case Efl.Dadi.start do
        {:ok, _pid} -> :ok
        {:error, :already_running} -> :ok  # Already running is fine for this test
      end

      # Give it a moment to register
      :timer.sleep(100)

      # Try to start again - should get already running message
      conn = get(conn, "/dadi/scratch")
      response = text_response(conn, 200)
      assert response =~ "DADI processing already in progress"

      # Clean up
      Efl.Dadi.stop
    end
  end

  describe "GET /dadi/status" do
    test "returns running status when process is active", %{conn: conn} do
      # Mock remote_ip to simulate localhost
      conn = %{conn | remote_ip: {127, 0, 0, 1}}

      # Start a process using the real Dadi.start function
      case Efl.Dadi.start do
        {:ok, _pid} -> :ok
        {:error, :already_running} -> :ok  # Already running is fine for this test
      end

      # Give it a moment to register
      :timer.sleep(100)

      conn = get(conn, "/dadi/status")
      response = text_response(conn, 200)
      assert response =~ "Running"

      # Clean up
      Efl.Dadi.stop
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

      # Start a process using the real Dadi.start function
      case Efl.Dadi.start do
        {:ok, _pid} -> :ok
        {:error, :already_running} -> :ok  # Already running is fine for this test
      end

      # Give it a moment to register
      :timer.sleep(100)

      conn = get(conn, "/dadi/stop")
      response = text_response(conn, 200)
      assert response =~ "DADI processing stopped successfully"

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