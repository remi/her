require "spec_helper"

describe Her::JsonApi::Model do
  before do
    Her::API.setup url: "https://api.example.com" do |connection|
      connection.use Her::Middleware::JsonApiParser
      connection.adapter :test do |stub|
        stub.get("/users/1") do
          [
            200,
            {},
            {
              data: {
                id:    1,
                type: "users",
                attributes: {
                  name: "Roger Federer"
                }
              }

            }.to_json
          ]
        end

        stub.get("/users") do
          [
            200,
            {},
            {
              data: [
                {
                  id:    1,
                  type: "users",
                  attributes: {
                    name: "Roger Federer"
                  }
                },
                {
                  id:    2,
                  type: "users",
                  attributes: {
                    name: "Kei Nishikori"
                  }
                }
              ]
            }.to_json
          ]
        end

        stub.post("/users", data:
        {
          type: "users",
          attributes: {
            name: "Jeremy Lin"
          }
        }) do
          [
            201,
            {},
            {
              data: {
                id:    3,
                type: "users",
                attributes: {
                  name: "Jeremy Lin"
                }
              }

            }.to_json
          ]
        end

        stub.patch("/users/1", data:
        {
          type: "users",
          id: 1,
          attributes: {
            name: "Fed GOAT"
          }
        }) do
          [
            200,
            {},
            {
              data: {
                id:    1,
                type: "users",
                attributes: {
                  name: "Fed GOAT"
                }
              }

            }.to_json
          ]
        end

        stub.delete("/users/1") do
          [204, {}, {}]
        end
      end
    end

    spawn_model("Foo::User", type: Her::JsonApi::Model)
  end

  it "allows configuration of type" do
    spawn_model("Foo::Bar", type: Her::JsonApi::Model) do
      type :foobars
    end

    expect(Foo::Bar.instance_variable_get("@type")).to eql("foobars")
  end

  it "finds models by id" do
    user = Foo::User.find(1)
    expect(user.attributes).to eql(
      "id" => 1,
      "name" => "Roger Federer"
    )
  end

  it "finds a collection of models" do
    users = Foo::User.all
    expect(users.map(&:attributes)).to match_array(
      [
        {
          "id" => 1,
          "name" => "Roger Federer"
        },
        {
          "id" => 2,
          "name" => "Kei Nishikori"
        }
      ]
    )
  end

  it "creates a Foo::User" do
    user = Foo::User.new(name: "Jeremy Lin")
    user.save
    expect(user.attributes).to eql(
      "id" => 3,
      "name" => "Jeremy Lin"
    )
  end

  it "updates a Foo::User" do
    user = Foo::User.find(1)
    user.name = "Fed GOAT"
    user.save
    expect(user.attributes).to eql(
      "id" => 1,
      "name" => "Fed GOAT"
    )
  end

  it "destroys a Foo::User" do
    user = Foo::User.find(1)
    expect(user.destroy).to be_destroyed
  end

  context "undefined methods" do
    it "removes methods that are not compatible with json api" do
      [:parse_root_in_json, :include_root_in_json, :root_element, :primary_key].each do |method|
        expect { Foo::User.new.send(method, :foo) }.to raise_error NoMethodError, "Her::JsonApi::Model does not support the #{method} configuration option"
      end
    end
  end
end
