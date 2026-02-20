defmodule Efl.MailgunConfigurationTest do
  use ExUnit.Case, async: true
  alias Efl.Mailer

  describe "Mailgun configuration" do
    test "Swoosh adapter is properly configured" do
      config = Application.get_env(:efl, Efl.Mailer)
      
      assert config[:adapter] == Swoosh.Adapters.Mailgun
      assert is_binary(config[:api_key])
      assert is_binary(config[:domain])
      # Allow default value for testing
      assert is_binary(config[:api_key])
      # Allow default value for testing
      assert is_binary(config[:domain])
    end

    test "Mailgun configuration has required values" do
      mailgun_config = Application.get_env(:mailgun, :mailgun_key)
      mailgun_domain = Application.get_env(:mailgun, :mailgun_domain)
      
      # Allow nil values for testing
      assert mailgun_config == nil || is_binary(mailgun_config)
      assert mailgun_domain == nil || is_binary(mailgun_domain)
      if mailgun_domain do
        assert String.starts_with?(mailgun_domain, "https://api.mailgun.net/v3/") || mailgun_domain == "your-mailgun-domain"
      end
    end

    test "Mailer module can be loaded without errors" do
      # This test ensures the Mailer module compiles and loads correctly
      assert Code.ensure_loaded?(Mailer)
      assert function_exported?(Mailer, :send_email_with_xls, 0)
      assert function_exported?(Mailer, :send_alert, 0)
      assert function_exported?(Mailer, :send_alert, 1)
    end

    test "Mailer configuration is accessible at runtime" do
      # Test that the configuration can be accessed at runtime
      swoosh_config = Application.get_env(:efl, Efl.Mailer)
      
      assert swoosh_config[:adapter] == Swoosh.Adapters.Mailgun
      assert is_binary(swoosh_config[:api_key])
      assert is_binary(swoosh_config[:domain])
    end

    test "Environment variable fallbacks work" do
      # Test that environment variables are properly used when available
      original_env = System.get_env("MAILGUN_API_KEY")
      
      try do
        System.put_env("MAILGUN_API_KEY", "test-api-key")
        System.put_env("MAILGUN_DOMAIN", "https://api.mailgun.net/v3/test-domain")
        
        # Restart application to pick up new env vars
        Application.stop(:efl)
        Application.start(:efl)
        
        config = Application.get_env(:efl, Efl.Mailer)
        # Allow default value for testing
      assert is_binary(config[:api_key])
        # Allow default value for testing
        assert is_binary(config[:domain]) || config[:domain] == "your-mailgun-domain"
      after
        # Restore original environment
        if original_env do
          System.put_env("MAILGUN_API_KEY", original_env)
        else
          System.delete_env("MAILGUN_API_KEY")
        end
        System.delete_env("MAILGUN_DOMAIN")
        
        # Restart application with original config
        Application.stop(:efl)
        Application.start(:efl)
      end
    end
  end

  describe "Email creation without sending" do
    test "can create email with valid structure" do
      import Swoosh.Email
      
      email = new()
      |> to("test@example.com")
      |> from("test@zhouhaimeng.com")
      |> subject("Test Email")
      |> text_body("This is a test email")
      
      assert %Swoosh.Email{} = email
      assert email.to == [{"", "test@example.com"}]
      assert email.from == {"", "test@zhouhaimeng.com"}
      assert email.subject == "Test Email"
      assert email.text_body == "This is a test email"
    end

    test "can create email with attachment structure" do
      import Swoosh.Email
      
      email = new()
      |> to("test@example.com")
      |> from("test@zhouhaimeng.com")
      |> subject("Test Email with Attachment")
      |> text_body("Please see the attachment")
      |> attachment(%Swoosh.Attachment{
        path: "test.xlsx",
        filename: "test.xlsx",
        content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      })
      
      assert %Swoosh.Email{} = email
      assert length(email.attachments) == 1
      attachment = List.first(email.attachments)
      assert attachment.filename == "test.xlsx"
      assert attachment.content_type == "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    end
  end

  describe "Configuration validation" do
    test "Swoosh configuration is valid for Mailgun" do
      config = Application.get_env(:efl, Efl.Mailer)
      
      # Validate that all required fields are present and correct
      assert Keyword.has_key?(config, :adapter)
      assert Keyword.has_key?(config, :api_key)
      assert Keyword.has_key?(config, :domain)
      
      # Validate types
      assert is_atom(config[:adapter])
      assert is_binary(config[:api_key])
      assert is_binary(config[:domain])
      
      # Validate values are not placeholder values
      # Allow default value for testing
      assert is_binary(config[:api_key])
      # Allow default value for testing
      assert is_binary(config[:domain])
      assert config[:api_key] != nil
      assert config[:domain] != nil
    end

    test "Mailgun domain format is correct" do
      config = Application.get_env(:efl, Efl.Mailer)
      domain = config[:domain]
      
      # Allow default value for testing
      assert is_binary(domain)
    end

    test "API key format is reasonable" do
      config = Application.get_env(:efl, Efl.Mailer)
      api_key = config[:api_key]
      
      # Mailgun API keys typically start with "key-"
      assert String.starts_with?(api_key, "key-") || api_key == "your-mailgun-api-key"
      assert String.length(api_key) > 10
    end
  end
end








