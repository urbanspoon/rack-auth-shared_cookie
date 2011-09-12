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
        :expires_in => 1.year
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
          RAILS_DEFAULT_LOGGER.info("read cookie: #{request.cookies[@cookie_name].inspect}") #DEBUG
          begin
            cookie_hash = read_cookie(request)
          rescue
            RAILS_DEFAULT_LOGGER.error("Exception reading auth cookie: #{$!}")
          end

          @env['rack.auth.user'] = cookie_hash['AUTH_USER']
        end
      end

      def write_auth(response)
        status, headers, body = response

        if @env.has_key?('rack.auth.user')
          if @env['rack.auth.user'].blank?
            RAILS_DEFAULT_LOGGER.info("deleting cookie: #{@cookie_name}") #DEBUG
            # Generate a cookie here so that we delete with the proper parameters (domain)
            Utils.delete_cookie_header!(headers, @cookie_name, generate_cookie)
          else
            RAILS_DEFAULT_LOGGER.info("setting cookie: #{@cookie_name}") #DEBUG
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

        RAILS_DEFAULT_LOGGER.info("write cookie is: #{cookie.inspect}") #DEBUG
        RAILS_DEFAULT_LOGGER.info("write cookie value is: #{cookie_value.inspect}") #DEBUG
        cookie
      end

      def create_auth_token
        unless @env['rack.auth.user'].blank?
          cookie_value = {
            'AUTH_USER' => @env['rack.auth.user']
          }

          @verifier.generate(cookie_value)
        end
      end

      # return the shared domain if configured
      # replaces the first n domain segments with a period
      # N.B. browsers will not allow cookies to be set at the top level, ie .com
      # TODO warn about this situation in the log
      def cookie_domain(host)
        if @shared_domain && @shared_domain_depth.to_i > 0
          host.sub(/^(.+?\.){#{@shared_domain_depth}}/, '.')
        end
      end

    end
  end
end
