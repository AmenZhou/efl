defmodule Efl.EmailDuplicationTest do
  use Efl.ModelCase, async: false
  alias Efl.Dadi
  alias Efl.Mailer

  describe "email duplication prevention" do
    test "prevents multiple email sends from concurrent processes" do
      # This test verifies that the process management prevents
      # multiple email sends from happening simultaneously
      
      # Mock the email sending to track calls
      email_calls = Agent.start_link(fn -> 0 end, name: :email_call_counter)
      
      # Override the email sending function to count calls
      defmodule TestMailer do
        def send_email_with_xls do
          Agent.update(:email_call_counter, &(&1 + 1))
          {:ok, :email_sent}
        end
      end
      
      # Mock the main function to call our test mailer
      defmodule TestDadi do
        def start do
          case Process.whereis(:dadi_processor) do
            nil ->
              {:ok, pid} = Task.start_link(fn -> 
                Process.register(self(), :dadi_processor)
                # Simulate quick processing
                :timer.sleep(100)
                # Call email sending
                TestMailer.send_email_with_xls()
                Process.unregister(:dadi_processor)
              end)
              {:ok, pid}
            pid when is_pid(pid) ->
              {:error, :already_running}
          end
        end
      end
      
      # Start multiple processes concurrently
      tasks = for _ <- 1..5 do
        Task.async(fn -> TestDadi.start end)
      end
      
      results = Task.await_many(tasks)
      
      # Only one should succeed
      success_count = Enum.count(results, fn result -> 
        match?({:ok, _pid}, result)
      end)
      
      assert success_count == 1
      
      # Wait for completion
      :timer.sleep(200)
      
      # Check email was sent only once
      email_count = Agent.get(:email_call_counter)
      assert email_count == 1
      
      # Clean up
      Agent.stop(:email_call_counter)
      case Process.whereis(:dadi_processor) do
        nil -> :ok
        pid -> 
          Process.exit(pid, :kill)
          Process.unregister(:dadi_processor)
      end
    end

    test "process cleanup prevents hanging processes" do
      # This test verifies that processes clean up properly
      # and don't hang after completion
      
      defmodule TestDadiCleanup do
        def start do
          case Process.whereis(:dadi_processor) do
            nil ->
              {:ok, pid} = Task.start_link(fn -> 
                Process.register(self(), :dadi_processor)
                # Simulate processing
                :timer.sleep(100)
                # Simulate email sending
                :ok
                # Process should unregister itself
                Process.unregister(:dadi_processor)
              end)
              {:ok, pid}
            pid when is_pid(pid) ->
              {:error, :already_running}
          end
        end
      end
      
      # Start process
      {:ok, pid} = TestDadiCleanup.start
      assert is_pid(pid)
      
      # Wait for completion
      :timer.sleep(200)
      
      # Process should be unregistered
      assert Process.whereis(:dadi_processor) == nil
      
      # Should be able to start a new process
      {:ok, new_pid} = TestDadiCleanup.start
      assert is_pid(new_pid)
      assert new_pid != pid
      
      # Clean up
      Process.exit(new_pid, :kill)
      Process.unregister(:dadi_processor)
    end

    test "concurrent start requests are handled atomically" do
      # This test ensures that concurrent start requests
      # don't result in race conditions
      
      defmodule TestDadiAtomic do
        def start do
          case Process.whereis(:dadi_processor) do
            nil ->
              # Add a small delay to simulate race condition
              :timer.sleep(10)
              case Process.whereis(:dadi_processor) do
                nil ->
                  {:ok, pid} = Task.start_link(fn -> 
                    Process.register(self(), :dadi_processor)
                    :timer.sleep(100)
                    Process.unregister(:dadi_processor)
                  end)
                  {:ok, pid}
                _pid ->
                  {:error, :already_running}
              end
            pid when is_pid(pid) ->
              {:error, :already_running}
          end
        end
      end
      
      # Start many processes simultaneously
      tasks = for _ <- 1..20 do
        Task.async(fn -> TestDadiAtomic.start end)
      end
      
      results = Task.await_many(tasks)
      
      # Only one should succeed
      success_count = Enum.count(results, fn result -> 
        match?({:ok, _pid}, result)
      end)
      
      error_count = Enum.count(results, fn result -> 
        result == {:error, :already_running}
      end)
      
      assert success_count == 1
      assert error_count == 19
      
      # Clean up
      case Process.whereis(:dadi_processor) do
        nil -> :ok
        pid -> 
          Process.exit(pid, :kill)
          Process.unregister(:dadi_processor)
      end
    end

    test "process status tracking works correctly" do
      # This test verifies that the status tracking
      # accurately reflects the process state
      
      defmodule TestDadiStatus do
        def start do
          case Process.whereis(:dadi_processor) do
            nil ->
              {:ok, pid} = Task.start_link(fn -> 
                Process.register(self(), :dadi_processor)
                :timer.sleep(200)
                Process.unregister(:dadi_processor)
              end)
              {:ok, pid}
            pid when is_pid(pid) ->
              {:error, :already_running}
          end
        end
        
        def status do
          case Process.whereis(:dadi_processor) do
            nil -> {:not_running, nil}
            pid when is_pid(pid) -> {:running, pid}
          end
        end
      end
      
      # Initially not running
      {:not_running, nil} = TestDadiStatus.status
      
      # Start process
      {:ok, pid} = TestDadiStatus.start
      assert is_pid(pid)
      
      # Should be running
      {:running, ^pid} = TestDadiStatus.status
      
      # Wait for completion
      :timer.sleep(300)
      
      # Should be not running again
      {:not_running, nil} = TestDadiStatus.status
    end

    test "error handling in process management" do
      # This test verifies that errors in process management
      # are handled gracefully
      
      defmodule TestDadiError do
        def start do
          case Process.whereis(:dadi_processor) do
            nil ->
              {:ok, pid} = Task.start_link(fn -> 
                Process.register(self(), :dadi_processor)
                # Simulate an error
                raise "Test error"
              end)
              {:ok, pid}
            pid when is_pid(pid) ->
              {:error, :already_running}
          end
        end
      end
      
      # Start process that will error
      {:ok, pid} = TestDadiError.start
      assert is_pid(pid)
      
      # Wait for error to occur
      :timer.sleep(100)
      
      # Process should be unregistered due to error
      assert Process.whereis(:dadi_processor) == nil
      
      # Should be able to start a new process
      {:ok, new_pid} = TestDadiError.start
      assert is_pid(new_pid)
      assert new_pid != pid
      
      # Clean up
      Process.exit(new_pid, :kill)
      Process.unregister(:dadi_processor)
    end
  end

  describe "integration with real Dadi module" do
    test "Dadi.start prevents duplicate processes" do
      # Ensure clean state
      case Process.whereis(:dadi_processor) do
        nil -> :ok
        pid -> 
          Process.exit(pid, :kill)
          Process.unregister(:dadi_processor)
      end
      
      # Start first process
      {:ok, pid1} = Dadi.start
      assert is_pid(pid1)
      
      # Try to start second process
      {:error, :already_running} = Dadi.start
      
      # Status should show running
      {:running, ^pid1} = Dadi.status
      
      # Clean up
      Process.exit(pid1, :kill)
      Process.unregister(:dadi_processor)
    end

    test "Dadi.stop works correctly" do
      # Start process
      {:ok, pid} = Dadi.start
      assert is_pid(pid)
      
      # Stop process
      {:ok, :stopped} = Dadi.stop
      
      # Status should show not running
      {:not_running, nil} = Dadi.status
    end

    test "complete workflow with Dadi module" do
      # Ensure clean state
      case Process.whereis(:dadi_processor) do
        nil -> :ok
        pid -> 
          Process.exit(pid, :kill)
          Process.unregister(:dadi_processor)
      end
      
      # 1. Start process
      {:ok, pid} = Dadi.start
      assert is_pid(pid)
      
      # 2. Check status
      {:running, ^pid} = Dadi.status
      
      # 3. Try to start again (should fail)
      {:error, :already_running} = Dadi.start
      
      # 4. Stop process
      {:ok, :stopped} = Dadi.stop
      
      # 5. Check final status
      {:not_running, nil} = Dadi.status
      
      # 6. Should be able to start again
      {:ok, new_pid} = Dadi.start
      assert is_pid(new_pid)
      assert new_pid != pid
      
      # Clean up
      Process.exit(new_pid, :kill)
      Process.unregister(:dadi_processor)
    end
  end
end
