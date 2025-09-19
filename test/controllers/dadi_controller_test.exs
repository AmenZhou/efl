defmodule Efl.DadiControllerTest do
  use Efl.ConnCase, async: true

  alias Efl.Dadi
  alias Efl.RefCategory

  setup do
    # Create test data
    ref_category = %RefCategory{
      name: "test_category",
      display_name: "Test Category",
      page_size: 5
    } |> Repo.insert!()

    dadi_post = %Dadi{
      title: "Test Post",
      url: "https://example.com/test",
      content: "Test content",
      phone: "123-456-7890",
      post_date: ~D[2024-01-15],
      ref_category_id: ref_category.id
    } |> Repo.insert!()

    {:ok, ref_category: ref_category, dadi_post: dadi_post}
  end

  describe "GET /" do
    test "renders the index page with posts", %{conn: conn, dadi_post: dadi_post} do
      conn = get(conn, "/")
      
      assert html_response(conn, 200) =~ "Test Post"
      assert html_response(conn, 200) =~ "https://example.com/test"
    end

    test "renders empty page when no posts exist", %{conn: conn} do
      # Clear all posts
      Repo.delete_all(Dadi)
      
      conn = get(conn, "/")
      assert html_response(conn, 200)
    end
  end

  describe "GET /dadi/scratch" do
    test "returns permission denied for non-localhost IP", %{conn: conn} do
      # Mock remote_ip to simulate non-localhost
      conn = %{conn | remote_ip: {192, 168, 1, 100}}
      
      conn = get(conn, "/dadi/scratch")
      assert text_response(conn, 200) =~ "No permission"
    end

    test "starts processing successfully for localhost IP", %{conn: conn} do
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
      assert response =~ "DADI processing started successfully"
      assert response =~ "PID"
      
      # Clean up
      case Process.whereis(:dadi_processor) do
        nil -> :ok
        pid -> 
          Process.exit(pid, :kill)
          Process.unregister(:dadi_processor)
      end
    end

    test "returns already running message when process is active", %{conn: conn} do
      # Mock remote_ip to simulate localhost
      conn = %{conn | remote_ip: {127, 0, 0, 1}}
      
      # Start a process first
      {:ok, pid} = Dadi.start
      assert is_pid(pid)
      
      # Try to start another process
      conn = get(conn, "/dadi/scratch")
      response = text_response(conn, 200)
      assert response =~ "DADI processing already in progress"
      
      # Clean up
      Process.exit(pid, :kill)
      Process.unregister(:dadi_processor)
    end
  end

  describe "GET /dadi/status" do
    test "returns not running when no process is active", %{conn: conn} do
      # Ensure no process is running
      case Process.whereis(:dadi_processor) do
        nil -> :ok
        pid -> 
          Process.exit(pid, :kill)
          Process.unregister(:dadi_processor)
      end
      
      conn = get(conn, "/dadi/status")
      assert text_response(conn, 200) =~ "DADI processing: Not running"
    end

    test "returns running status when process is active", %{conn: conn} do
      # Start a process
      {:ok, pid} = Dadi.start
      assert is_pid(pid)
      
      conn = get(conn, "/dadi/status")
      response = text_response(conn, 200)
      assert response =~ "DADI processing: Running"
      assert response =~ "PID"
      
      # Clean up
      Process.exit(pid, :kill)
      Process.unregister(:dadi_processor)
    end
  end

  describe "GET /dadi/stop" do
    test "returns permission denied for non-localhost IP", %{conn: conn} do
      # Mock remote_ip to simulate non-localhost
      conn = %{conn | remote_ip: {192, 168, 1, 100}}
      
      conn = get(conn, "/dadi/stop")
      assert text_response(conn, 200) =~ "No permission"
    end

    test "stops running process for localhost IP", %{conn: conn} do
      # Mock remote_ip to simulate localhost
      conn = %{conn | remote_ip: {127, 0, 0, 1}}
      
      # Start a process first
      {:ok, pid} = Dadi.start
      assert is_pid(pid)
      
      # Stop the process
      conn = get(conn, "/dadi/stop")
      assert text_response(conn, 200) =~ "DADI processing stopped successfully"
      
      # Verify process is stopped
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

  describe "process management integration" do
    test "complete workflow: start, check status, stop", %{conn: conn} do
      # Mock remote_ip to simulate localhost
      conn = %{conn | remote_ip: {127, 0, 0, 1}}
      
      # Ensure clean state
      case Process.whereis(:dadi_processor) do
        nil -> :ok
        pid -> 
          Process.exit(pid, :kill)
          Process.unregister(:dadi_processor)
      end
      
      # 1. Check initial status
      conn = get(conn, "/dadi/status")
      assert text_response(conn, 200) =~ "Not running"
      
      # 2. Start process
      conn = get(conn, "/dadi/scratch")
      response = text_response(conn, 200)
      assert response =~ "started successfully"
      
      # 3. Check running status
      conn = get(conn, "/dadi/status")
      response = text_response(conn, 200)
      assert response =~ "Running"
      
      # 4. Try to start again (should fail)
      conn = get(conn, "/dadi/scratch")
      response = text_response(conn, 200)
      assert response =~ "already in progress"
      
      # 5. Stop process
      conn = get(conn, "/dadi/stop")
      response = text_response(conn, 200)
      assert response =~ "stopped successfully"
      
      # 6. Check final status
      conn = get(conn, "/dadi/status")
      assert text_response(conn, 200) =~ "Not running"
    end

    test "handles concurrent requests gracefully", %{conn: conn} do
      # Mock remote_ip to simulate localhost
      conn = %{conn | remote_ip: {127, 0, 0, 1}}
      
      # Ensure clean state
      case Process.whereis(:dadi_processor) do
        nil -> :ok
        pid -> 
          Process.exit(pid, :kill)
          Process.unregister(:dadi_processor)
      end
      
      # Start first process
      conn1 = get(conn, "/dadi/scratch")
      response1 = text_response(conn1, 200)
      assert response1 =~ "started successfully"
      
      # Try to start multiple processes concurrently
      tasks = for _ <- 1..5 do
        Task.async(fn -> 
          conn = %{conn | remote_ip: {127, 0, 0, 1}}
          get(conn, "/dadi/scratch")
        end)
      end
      
      results = Task.await_many(tasks)
      
      # All should return already running message
      Enum.each(results, fn conn ->
        response = text_response(conn, 200)
        assert response =~ "already in progress"
      end)
      
      # Clean up
      case Process.whereis(:dadi_processor) do
        nil -> :ok
        pid -> 
          Process.exit(pid, :kill)
          Process.unregister(:dadi_processor)
      end
    end
  end
end
