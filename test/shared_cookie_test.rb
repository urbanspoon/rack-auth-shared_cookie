require 'rubygems'
require 'bundler/setup'
require 'minitest/spec'
require 'minitest/autorun'
require 'rack/auth/shared_cookie'

describe Rack::Auth::SharedCookie do

  it 'should read cookie'
  it 'should write cookie'

  describe 'cookie_domain' do
    def generate(options={})
      Rack::Auth::SharedCookie.new(nil, options.merge(:secret => '1'))
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
