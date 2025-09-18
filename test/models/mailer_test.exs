defmodule Efl.MailerTest do
  use Efl.ModelCase, async: true

  alias Efl.Mailer
  alias Efl.Xls.Dadi
  alias Efl.Dadi, as: DadiModel
  alias Efl.RefCategory
  alias Efl.Repo

  setup do
    # Create test data
    ref_category = %RefCategory{
      name: "test_category",
      display_name: "Test Category",
      page_size: 5
    } |> Repo.insert!()

    # Create some test dadi records
    yesterday = Efl.TimeUtil.target_date()
    
    dadi1 = %DadiModel{
      title: "Test Post 1",
      url: "https://example.com/test1",
      content: "Test content 1",
      phone: "123-456-7890",
      post_date: yesterday,
      ref_category_id: ref_category.id
    } |> Repo.insert!()

    {:ok, ref_category: ref_category, dadi1: dadi1}
  end

  describe "send_email_with_xls/0" do
    test "sends email when Excel file has data", %{ref_category: ref_category} do
      # Ensure we have data
      dadi_count = Repo.aggregate(DadiModel, :count, :id)
      assert dadi_count > 0

      # Create Excel file first
      Dadi.create_xls()
      file_name = Dadi.file_name()
      
      # Mock the email delivery
      with_mock Swoosh.Mailer, [:passthrough], [] do
        # Mock the deliver function to return success
        expect(Swoosh.Mailer, :deliver, fn _email -> {:ok, %{id: "test-email-id"}} end)
        
        # Call the function
        result = Mailer.send_email_with_xls()
        
        # Should return success
        assert result == %{id: "test-email-id"}
      end
      
      # Clean up
      File.rm!(file_name)
    end

    test "skips email when Excel file is too small" do
      # Clear all data to create empty file
      Repo.delete_all(DadiModel)
      
      # Create empty Excel file
      Dadi.create_xls()
      file_name = Dadi.file_name()
      
      # Mock the alert sending
      with_mock Mailer, [:passthrough], [] do
        # Mock send_alert to track calls
        expect(Mailer, :send_alert, fn message -> 
          assert String.contains?(message, "Excel file is empty or too small")
          :ok
        end)
        
        # Call the function
        result = Mailer.send_email_with_xls()
        
        # Should not send email, just call alert
        assert result == :ok
      end
      
      # Clean up
      File.rm!(file_name)
    end

    test "sends alert when Excel file does not exist" do
      # Mock the alert sending
      with_mock Mailer, [:passthrough], [] do
        # Mock send_alert to track calls
        expect(Mailer, :send_alert, fn message -> 
          assert String.contains?(message, "Excel file does not exist")
          :ok
        end)
        
        # Call the function without creating file
        result = Mailer.send_email_with_xls()
        
        # Should not send email, just call alert
        assert result == :ok
      end
    end

    test "sends alert when email delivery fails" do
      # Ensure we have data
      dadi_count = Repo.aggregate(DadiModel, :count, :id)
      assert dadi_count > 0

      # Create Excel file first
      Dadi.create_xls()
      file_name = Dadi.file_name()
      
      # Mock the email delivery to fail
      with_mock Swoosh.Mailer, [:passthrough], [] do
        # Mock the deliver function to return error
        expect(Swoosh.Mailer, :deliver, fn _email -> {:error, "SMTP error"} end)
        
        # Mock send_alert to track calls
        expect(Mailer, :send_alert, fn -> :ok end)
        
        # Call the function
        result = Mailer.send_email_with_xls()
        
        # Should call alert due to delivery failure
        assert result == :ok
      end
      
      # Clean up
      File.rm!(file_name)
    end
  end

  describe "send_alert/0" do
    test "sends alert email" do
      # Mock the email delivery
      with_mock Swoosh.Mailer, [:passthrough], [] do
        # Mock the deliver function
        expect(Swoosh.Mailer, :deliver, fn email -> 
          # Verify email structure
          assert email.to != nil
          assert email.from != nil
          assert String.contains?(email.subject, "Alert!")
          assert String.contains?(email.text_body, "excel file")
          {:ok, %{id: "alert-email-id"}}
        end)
        
        # Call the function
        result = Mailer.send_alert()
        
        # Should return success
        assert result == %{id: "alert-email-id"}
      end
    end
  end

  describe "send_alert/1" do
    test "sends alert email with custom message" do
      custom_message = "Test alert message"
      
      # Mock the email delivery
      with_mock Swoosh.Mailer, [:passthrough], [] do
        # Mock the deliver function
        expect(Swoosh.Mailer, :deliver, fn email -> 
          # Verify email structure
          assert email.to != nil
          assert email.from != nil
          assert String.contains?(email.subject, "Alert!")
          assert String.contains?(email.text_body, custom_message)
          {:ok, %{id: "alert-email-id"}}
        end)
        
        # Call the function
        result = Mailer.send_alert(custom_message)
        
        # Should return success
        assert result == %{id: "alert-email-id"}
      end
    end
  end

  describe "email structure" do
    test "creates email with correct structure" do
      # Create a test Excel file
      Dadi.create_xls()
      file_name = Dadi.file_name()
      
      # Mock the email creation
      with_mock Swoosh.Mailer, [:passthrough], [] do
        # Mock the deliver function to capture email
        expect(Swoosh.Mailer, :deliver, fn email -> 
          # Verify email structure
          assert email.to != nil
          assert email.from != nil
          assert String.contains?(email.subject, "DADI 360")
          assert String.contains?(email.subject, file_name)
          assert String.contains?(email.text_body, "Please see the attachment")
          assert length(email.attachments) == 1
          
          attachment = List.first(email.attachments)
          assert attachment.filename == file_name
          assert attachment.content_type == "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
          
          {:ok, %{id: "test-email-id"}}
        end)
        
        # Call the function
        Mailer.send_email_with_xls()
      end
      
      # Clean up
      File.rm!(file_name)
    end
  end
end