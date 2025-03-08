# Crawler

This project is for a special usage on my own, more for fun. My first Elixir+Phoenix project.


## Install on Ubuntu

`apt-get install build-essential`

#### Install asdf

[Reference](http://asdf-vm.com/guide/getting-started.html#_1-install-dependencies)

#### Install Elixir

`asdf plugin-add elixir`

`asdf install elixir 1.10.4`

#### Install Erlang
`asdf plugin-add erlang`

`asdf install erlang 22.3.4.20`

#### Set up mysql
`apt-get install mysql-server`

`CREATE USER 'hzhou'@'localhost'IDENTIFIED WITH mysql_native_password BY '';`
`GRANT ALL PRIVILEGES ON * . * TO 'hzhou'@'localhost';`

#### Create DB

`MIX_ENV=prod mix ecto.create`
`MIX_ENV=prod mix ecto.reset`

### How to use Scraper API as an agent?

To integrate ScraperAPI into your Elixir-based web crawler project, you'll need to modify the components responsible for making HTTP requests. Here's how you can proceed:

1. **Identify HTTP Request Modules**:
   Examine your project's structure to locate the modules or functions handling HTTP requests. Common directories and files to inspect include:
   - `lib/`: Contains the main application code.
   - `web/`: Might contain web-related functionalities.
   - `config/`: Holds configuration files that might specify HTTP client settings.

   Look for files where HTTP requests are initiated, possibly using libraries like `HTTPoison`, `Tesla`, or native Erlang modules. For instance, if your project uses `HTTPoison`, you might find code snippets like `HTTPoison.get(url)` or `HTTPoison.post(url, body, headers)`.

2. **Modify HTTP Request Functions**:
   Once you've identified where HTTP requests are made, update these functions to route requests through ScraperAPI. This typically involves altering the request URL to include ScraperAPI's endpoint and your API key. For example, if using `HTTPoison`, you might adjust the request as follows:

   ```elixir
   def fetch_page(url) do
     api_key = "YOUR_SCRAPERAPI_KEY"
     scraperapi_url = "http://api.scraperapi.com/?api_key=#{api_key}&url=#{URI.encode(url)}"
     case HTTPoison.get(scraperapi_url) do
       {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
         {:ok, body}
       {:ok, %HTTPoison.Response{status_code: status_code}} ->
         {:error, "Received status code #{status_code}"}
       {:error, %HTTPoison.Error{reason: reason}} ->
         {:error, reason}
     end
   end
   ```

   Replace `"YOUR_SCRAPERAPI_KEY"` with your actual ScraperAPI key. This modification ensures that all HTTP requests are processed through ScraperAPI, benefiting from its features like proxy management and CAPTCHA handling.

3. **Test the Integration**:
   After making the necessary changes, thoroughly test your application to ensure that the integration works as expected. Check for successful data retrieval, proper error handling, and overall stability.

By focusing on the modules responsible for HTTP requests and updating them to utilize ScraperAPI, you can enhance your web crawler's robustness and efficiency. 

#### Seed
```
Efl.RefCategory.seeds
```
