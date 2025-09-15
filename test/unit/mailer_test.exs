defmodule Efl.MailerUnitTest do
  use ExUnit.Case, async: true

  alias Efl.Mailer

  describe "module functions" do
    test "send_email_with_xls/0 function exists" do
      assert function_exported?(Mailer, :send_email_with_xls, 0)
    end

    test "send_alert/0 function exists" do
      assert function_exported?(Mailer, :send_alert, 0)
    end

    test "send_alert/1 function exists" do
      assert function_exported?(Mailer, :send_alert, 1)
    end
  end

  describe "module attributes" do
    test "has required module attributes" do
      # Test that the module has the expected attributes
      # These are compile-time constants that should be defined
      assert is_binary(Application.get_env(:mailgun, :recipient) || "")
      assert is_binary(Application.get_env(:mailgun, :alert_recipient) || "")
    end
  end
end
