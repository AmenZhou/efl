#!/bin/bash

echo "🧪 EFL Production Email and Excel Test"
echo "======================================"
echo ""

# Check if we're in the right directory
if [ ! -f "mix.exs" ]; then
    echo "❌ Error: Please run this script from the project root directory"
    exit 1
fi

# Check if Docker is running
if ! docker-compose ps | grep -q "Up"; then
    echo "❌ Error: Docker containers are not running. Please run 'docker-compose up -d' first"
    exit 1
fi

echo "📋 Available Test Options:"
echo "1. Full test with Excel generation and detailed output"
echo "2. Simple test with basic CSV and email"
echo "3. Test in production mode"
echo ""

read -p "Choose test option (1-3): " choice

case $choice in
    1)
        echo "🚀 Running Full Email and Excel Test..."
        echo "======================================"
        docker-compose exec app mix run test_prod_email.exs
        ;;
    2)
        echo "🚀 Running Simple Email Test..."
        echo "============================="
        docker-compose exec app mix run test_prod_email_simple.exs
        ;;
    3)
        echo "🚀 Running Production Mode Test..."
        echo "================================"
        MIX_ENV=prod docker-compose exec app mix run test_prod_email_simple.exs
        ;;
    *)
        echo "❌ Invalid choice. Please run the script again and choose 1, 2, or 3"
        exit 1
        ;;
esac

echo ""
echo "✅ Test completed!"
echo ""
echo "💡 Tips:"
echo "- Check your email configuration in config/mailgun.exs"
echo "- Verify MAILGUN_API_KEY and MAILGUN_DOMAIN environment variables"
echo "- Check application logs for detailed error information"
echo "- The test uses 'test@example.com' as recipient - update if needed"
