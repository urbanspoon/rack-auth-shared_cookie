require 'rack/request'
require 'rack/utils'
require 'active_support/message_verifier'

module Rack
  module Auth
    # Authenticates users using a cookie that is optionally shared across subdomains
    class SharedCookie
      DEFAULT_OPTIONS = {
        :cookie_name => 'auth_token',
        :shared_domain => true,
        :shared_domain_depth => 1,
        :expires_in => 31557600 # 1.year
      }

      def initialize(app, options={})
        @app = app
        options = DEFAULT_OPTIONS.merge(options)
        @cookie_name = options[:cookie_name]
        @shared_domain = options[:shared_domain]
        @shared_domain_depth = options[:shared_domain_depth]
        @expires_in = options[:expires_in]

        raise "Rack::Auth::SharedCookie requires :secret option" unless options[:secret]
        @verifier = ActiveSupport::MessageVerifier.new(options[:secret])
      end

      def call(env)
        @env = env
        read_auth
        response = @app.call(env)
        write_auth(response)
      end

      def read_auth
        request = Rack::Request.new(@env)

        @env['rack.auth.domain'] = cookie_domain(request.host)

        unless request.cookies[@cookie_name].blank?
          begin
            cookie_hash = read_cookie(request)
          rescue
            RAILS_DEFAULT_LOGGER.error("[Rack::Auth::SharedCookie] Exception reading auth cookie: #{$!}")
          end

          @env['rack.auth.user'] = cookie_hash['AUTH_USER']
        end
      end

      def write_auth(response)
        status, headers, body = response

        if @env.has_key?('rack.auth.user')
          if @env['rack.auth.user'].blank?
            # Generate a cookie here so that we delete with the proper parameters (domain)
            Utils.delete_cookie_header!(headers, @cookie_name, generate_cookie.merge(:expires => Time.at(0)))
          else
            Utils.set_cookie_header!(headers, @cookie_name, generate_cookie)
          end
        end

        [status, headers, body]
      end

      def read_cookie(request)
        @verifier.verify(request.cookies[@cookie_name])
      end

      def generate_cookie
        cookie = {
            :value => create_auth_token,
            :path => '/',
            :expires => Time.now + @expires_in,
            :httponly => true
        }

        cookie[:domain] = @env['rack.auth.domain'] unless @env['rack.auth.domain'].blank?
        cookie
      end

      def create_auth_token
        @verifier.generate({
          'AUTH_USER' => @env['rack.auth.user']
        })
      end

      # return the shared domain if configured and valid
      # replaces the first n domain segments with a period
      def cookie_domain(host)
        if @shared_domain && @shared_domain_depth.to_i > 0
          domain = '.' + host.sub(/^(.+?\.){#{@shared_domain_depth}}/, '')

          # Browsers will not allow cookies to be set at the top level (.com) so warn about that
          if domain.split('.').size < 3 # split will return an empty string for leading .
            RAILS_DEFAULT_LOGGER.warn("[Rack::Auth::SharedCookie] #{domain} is not a valid cookie domain, must have at least 2 segments")
            domain = nil
          end
          domain
        end
      end
    end
  end
end
