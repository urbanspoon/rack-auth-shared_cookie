require File.join(File.dirname(__FILE__), 'test_helper')

describe Rack::Auth::SharedCookie do
  include Rack::Test::Methods

  let(:secret) { '1' }
  let(:verifier) { ActiveSupport::MessageVerifier.new(secret) }

  def app
    @target = lambda { [200, { }, "Test app"] }
  
    Rack::Auth::SharedCookie.new(@target, :secret => secret)
  end

  it 'should read cookie' do
    set_cookie("auth_token=#{verifier.generate('AUTH_USER' => 'a')};")
    get '/foo'
    last_request.env['rack.auth.user'].must_equal 'a'
  end

  it 'should write cookie' do
    get '/foo', {}, {'rack.auth.user' => 'a'}
    last_response.headers['Set-Cookie'].must_include verifier.generate('AUTH_USER' => 'a')
  end

  it 'should reject cookies with an invalid signature' do
    set_cookie("auth_token=#{verifier.generate('AUTH_USER' => 'a').succ};")
    get '/foo'
    last_request.env['rack.auth.user'].must_be_nil
  end

  it 'should write cookies with the shared domain' do
    get 'http://www.example.org/foo', {}, {'rack.auth.user' => 'a'}
    last_response.headers['Set-Cookie'].must_include "domain=.example.org"
  end

  describe 'cookie_domain' do
    def generate(options={})
      Rack::Auth::SharedCookie.new(nil, options.merge(:secret => secret))
    end

    it 'should return nil if shared_domain is false' do
      generate(:shared_domain => false).cookie_domain('www.example.com').must_be_nil
    end

    it 'should return nil if shared_domain_depth is not >0' do
      generate(:shared_domain_depth => 0).cookie_domain('www.example.com').must_be_nil
      generate(:shared_domain_depth => nil).cookie_domain('www.example.com').must_be_nil
      generate(:shared_domain_depth => "hi").cookie_domain('www.example.com').must_be_nil
    end

    it 'should return shared domain by default' do
      generate.cookie_domain('www.example.com').must_equal '.example.com'
      generate.cookie_domain('www1.www2.example.com').must_equal '.www2.example.com'
    end

    it 'should change shared_domain_depth' do
      generate(:shared_domain_depth => 2).cookie_domain('www1.www2.example.com').must_equal '.example.com'
    end
  end
end
