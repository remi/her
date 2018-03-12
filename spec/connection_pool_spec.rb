# encoding: utf-8
require File.join(File.dirname(__FILE__), "spec_helper.rb")
require 'her/api/connection_pool'

describe Her::API::ConnectionPool do
  it 'delegates http verb methods to connection' do
    connection = double
    pool = described_class.new { connection }
    expect(connection).to receive(:get)
    expect(connection).to receive(:post)
    expect(connection).to receive(:put)
    expect(connection).to receive(:patch)
    expect(connection).to receive(:delete)
    pool.get('/lol')
    pool.post('/lol')
    pool.put('/lol')
    pool.patch('/lol')
    pool.delete('/lol')
  end

  describe 'when using with API' do
    subject { Her::API.new }

    before do
      i = -1
      mutex = Mutex.new
      subject.setup :pool_size => 5, :url => "https://api.example.com" do |builder|
        builder.adapter(:test) do |stub|
          stub.get("/foo") do |env|
            sleep 0.025 # simulate slow response
            body = mutex.synchronize do
              "Foo, it is #{i += 1}."
            end
            [200, {}, body]
          end
        end
      end
    end

    its(:options) { should == {:pool_size => 5, :url => "https://api.example.com"} }

    it 'creates only `pool_size` connections' do
      should receive(:make_faraday_connection).exactly(5).times.and_call_original
      threads = 10.times.map do
        Thread.new do
          subject.request(:_method => :get, :_path => "/foo")
        end
      end
      threads.each(&:join)
    end

    it 'just does the same thing as a single connection' do
      threads = 10.times.map do
        Thread.new do
          subject.request(:_method => :get, :_path => "/foo")
        end
      end
      values = threads.map { |t| t.value[:parsed_data] }.sort
      expected_values = 10.times.map { |i| "Foo, it is #{i}." }
      expect(values).to eq(expected_values)
    end
  end
end
