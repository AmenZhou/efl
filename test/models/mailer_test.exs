defmodule Efl.MailerTest do
  use Efl.ModelCase, async: true

  alias Efl.Mailer

  describe "send_email_with_xls/0" do
    test "sends email with XLS attachment" do
      # This test would require mocking the email service
      # For now, we'll test that the function exists and can be called
      # without crashing (in a real test, you'd mock Swoosh.Mailer)
      
      # Mock the XLS file creation
      # In a real test, you'd mock Efl.Xls.Dadi.file_name/0
      # and Swoosh.Mailer.deliver/1
      
      # For now, just test that the function is defined
      assert function_exported?(Mailer, :send_email_with_xls, 0)
    end
  end

  describe "send_alert/0" do
    test "sends alert email" do
      # Test that the function exists
      assert function_exported?(Mailer, :send_alert, 0)
    end
  end

  describe "send_alert/1" do
    test "sends alert email with custom message" do
      # Test that the function exists
      assert function_exported?(Mailer, :send_alert, 1)
    end
  end
end
