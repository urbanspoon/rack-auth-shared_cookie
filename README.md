Rack::Auth::SharedCookie
========================

Description
-----------
Rack::Auth::SharedCookie is a rack middleware that uses a shared cookie to 
authenticate users across subdomains. It handles reading and writing the 
shared cookie, but not authenticating the user.

Prerequisites
-------------
rack 1.0.0 or later

Usage in Rails
--------------
require 'rack/auth/shared_cookie'

config.middleware.use "Rack::Auth::SharedCookie", :secret => "mylongsecret"
