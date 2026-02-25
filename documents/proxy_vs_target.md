# Why Valid Proxies Can Still Fail on c.dadi360.com

## What we verified

- **Proxies are valid**: The 5 HTTP proxies in `proxies.txt` were tested with `curl http://api.iplocate.io/ip --proxy http://IP:PORT` and returned a valid IP. So they correctly forward HTTP traffic.

## What happens in production

- **Same proxies** are used to fetch `http://c.dadi360.com/c/forums/show/...`.
- The **target (c.dadi360.com)** often responds with:
  - **400 Bad Request** (nginx)
  - **405 Not Allowed** (nginx)
  - **500 Internal Server Error** (Apache)
  - or **timeouts** / **connection closed**.

So the request **does** go through the proxy (we get an HTTP response from the origin), but the **destination site** is rejecting or failing the request.

## Likely reasons

1. **Target blocks or restricts proxy/datacenter IPs**  
   iplocate.io does not care who connects. c.dadi360.com (or its CDN/WAF) may block known proxy or datacenter IPs, or require “residential” IPs.

2. **Missing or bot-like User-Agent**  
   Our client did not set a `User-Agent` (or used a default that looks like a script). Many sites return 400/405 for requests without a browser-like User-Agent.

3. **Other anti-bot / header checks**  
   The site might expect headers such as `Accept`, `Accept-Language`, or `Referer`, and reject requests that look like scripts.

4. **Rate limiting or temporary errors**  
   Some responses (e.g. 500) may be due to rate limiting or server-side issues when seeing proxy traffic.

## What was changed

- **Browser-like User-Agent** was added in `HttpClient` so requests look like a normal browser. This often fixes 400/405 when the cause is User-Agent blocking.
- **SSL verification**: When using HTTP proxies to fetch HTTPS (e.g. c.dadi360.com), certificate verification is off by default to avoid failures behind some proxies. Set env `HTTP_SSL_VERIFY=true` to enable verification when appropriate. See `HttpClient.get/2` adapter opts.
- If it still fails, the next step is to try different proxies (e.g. residential) or inspect the exact response/headers from c.dadi360.com (e.g. via `curl -v` through one of the working proxies).
