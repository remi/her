# encoding: utf-8

require File.join(File.dirname(__FILE__), "spec_helper.rb")

describe Her::API do
  subject { Her::API.new }

  context "initialization" do
    describe "#setup" do
      context "when setting custom middleware" do
        before do
          class Foo; end
          class Bar; end

          subject.setup url: "https://api.example.com" do |connection|
            connection.use Foo
            connection.use Bar
          end
        end

        specify { expect(subject.connection.builder.handlers).to eq([Foo, Bar]) }
      end

      context "when setting custom options" do
        before { subject.setup foo: { bar: "baz" }, url: "https://api.example.com" }

        describe "#options" do
          it { expect(subject.options).to eq(foo: { bar: "baz" }, url: "https://api.example.com") }
        end
      end
    end

    describe "#request" do
      before do
        class SimpleParser < Faraday::Middleware

          def on_complete(env)
            env[:body] = { data: env[:body] }
          end
        end
      end

      context "making HTTP requests" do
        let(:parsed_data) { subject.request(_method: :get, _path: "/foo")[:parsed_data] }
        before do
          subject.setup url: "https://api.example.com" do |builder|
            builder.use SimpleParser
            builder.adapter(:test) { |stub| stub.get("/foo") { [200, {}, "Foo, it is."] } }
          end
        end

        specify { expect(parsed_data[:data]).to eq("Foo, it is.") }
      end

      context "making HTTP requests while specifying custom HTTP headers" do
        let(:parsed_data) { subject.request(_method: :get, _path: "/foo", _headers: { "X-Page" => 2 })[:parsed_data] }

        before do
          subject.setup url: "https://api.example.com" do |builder|
            builder.use SimpleParser
            builder.adapter(:test) { |stub| stub.get("/foo") { |env| [200, {}, "Foo, it is page #{env[:request_headers]['X-Page']}."] } }
          end
        end

        specify { expect(parsed_data[:data]).to eq("Foo, it is page 2.") }
      end

      context "parsing a request with the default parser" do
        let(:parsed_data) { subject.request(_method: :get, _path: "users/1")[:parsed_data] }
        before do
          subject.setup url: "https://api.example.com" do |builder|
            builder.use Her::Middleware::FirstLevelParseJSON
            builder.adapter :test do |stub|
              stub.get("/users/1") { [200, {}, MultiJson.dump(id: 1, name: "George Michael Bluth", errors: ["This is a single error"], metadata: { page: 1, per_page: 10 })] }
            end
          end
        end

        specify do
          expect(parsed_data[:data]).to eq(id: 1, name: "George Michael Bluth")
          expect(parsed_data[:errors]).to eq(["This is a single error"])
          expect(parsed_data[:metadata]).to eq(page: 1, per_page: 10)
        end
      end

      context "parsing a request with a custom parser" do
        let(:parsed_data) { subject.request(_method: :get, _path: "users/1")[:parsed_data] }
        before do
          class CustomParser < Faraday::Middleware

            def on_complete(env)
              json = MultiJson.load(env[:body], symbolize_keys: true)
              errors = json.delete(:errors) || []
              metadata = json.delete(:metadata) || {}
              env[:body] = {
                data: json,
                errors: errors,
                metadata: metadata
              }
            end
          end

          subject.setup url: "https://api.example.com" do |builder|
            builder.use CustomParser
            builder.use Faraday::Request::UrlEncoded
            builder.adapter :test do |stub|
              stub.get("/users/1") { [200, {}, MultiJson.dump(id: 1, name: "George Michael Bluth")] }
            end
          end
        end

        specify do
          expect(parsed_data[:data]).to eq(id: 1, name: "George Michael Bluth")
          expect(parsed_data[:errors]).to eq([])
          expect(parsed_data[:metadata]).to eq({})
        end
      end
    end
  end
end
