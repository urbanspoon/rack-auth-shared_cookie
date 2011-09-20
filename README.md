Rack::Auth::SharedCookie
========================

Description
-----------
Rack::Auth::SharedCookie is a rack middleware that uses a shared cookie to 
authenticate users across subdomains. It handles reading and writing the 
shared cookie, but not authenticating the user.

The application can read and write the auth token using the rack environment variable rack.auth.user:

<pre>
current_user = User.find_by_id(request.env['rack.auth.user'])

request.env['rack.auth.user'] = current_user.id
</pre>

Prerequisites
-------------
rack 1.0.0 or later

Usage in Rails
--------------
require 'rack/auth/shared_cookie'

config.middleware.use "Rack::Auth::SharedCookie", :secret => "mylongsecret"
