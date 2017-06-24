# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe Her::Model::Associations do
  context "setting associations without details" do
    before { spawn_model "Foo::User" }
    subject { Foo::User.associations }

    context "single has_many association" do
      before { Foo::User.has_many :comments }

      describe "[:has_many]" do
        subject { super()[:has_many] }
        it { is_expected.to eql [{ name: :comments, data_key: :comments, default: [], class_name: "Comment", path: "/comments", inverse_of: nil }] }
      end
    end

    context "multiple has_many associations" do
      before do
        Foo::User.has_many :comments
        Foo::User.has_many :posts
      end

      describe "[:has_many]" do
        subject { super()[:has_many] }
        it { is_expected.to eql [{ name: :comments, data_key: :comments, default: [], class_name: "Comment", path: "/comments", inverse_of: nil }, { name: :posts, data_key: :posts, default: [], class_name: "Post", path: "/posts", inverse_of: nil }] }
      end
    end

    context "single has_one association" do
      before { Foo::User.has_one :category }

      describe "[:has_one]" do
        subject { super()[:has_one] }
        it { is_expected.to eql [{ name: :category, data_key: :category, default: nil, class_name: "Category", path: "/category" }] }
      end
    end

    context "multiple has_one associations" do
      before do
        Foo::User.has_one :category
        Foo::User.has_one :role
      end

      describe "[:has_one]" do
        subject { super()[:has_one] }
        it { is_expected.to eql [{ name: :category, data_key: :category, default: nil, class_name: "Category", path: "/category" }, { name: :role, data_key: :role, default: nil, class_name: "Role", path: "/role" }] }
      end
    end

    context "single belongs_to association" do
      before { Foo::User.belongs_to :organization }

      describe "[:belongs_to]" do
        subject { super()[:belongs_to] }
        it { is_expected.to eql [{ name: :organization, data_key: :organization, default: nil, class_name: "Organization", foreign_key: "organization_id", path: "/organizations/:id" }] }
      end
    end

    context "multiple belongs_to association" do
      before do
        Foo::User.belongs_to :organization
        Foo::User.belongs_to :family
      end

      describe "[:belongs_to]" do
        subject { super()[:belongs_to] }
        it { is_expected.to eql [{ name: :organization, data_key: :organization, default: nil, class_name: "Organization", foreign_key: "organization_id", path: "/organizations/:id" }, { name: :family, data_key: :family, default: nil, class_name: "Family", foreign_key: "family_id", path: "/families/:id" }] }
      end
    end
  end

  context "setting associations with details" do
    before { spawn_model "Foo::User" }
    subject { Foo::User.associations }

    context "in base class" do
      context "single has_many association" do
        before { Foo::User.has_many :comments, class_name: "Post", inverse_of: :admin, data_key: :user_comments, default: {} }

        describe "[:has_many]" do
          subject { super()[:has_many] }
          it { is_expected.to eql [{ name: :comments, data_key: :user_comments, default: {}, class_name: "Post", path: "/comments", inverse_of: :admin }] }
        end
      end

      context "single has_one association" do
        before { Foo::User.has_one :category, class_name: "Topic", foreign_key: "topic_id", data_key: :topic, default: nil }

        describe "[:has_one]" do
          subject { super()[:has_one] }
          it { is_expected.to eql [{ name: :category, data_key: :topic, default: nil, class_name: "Topic", foreign_key: "topic_id", path: "/category" }] }
        end
      end

      context "single belongs_to association" do
        before { Foo::User.belongs_to :organization, class_name: "Business", foreign_key: "org_id", data_key: :org, default: true }

        describe "[:belongs_to]" do
          subject { super()[:belongs_to] }
          it { is_expected.to eql [{ name: :organization, data_key: :org, default: true, class_name: "Business", foreign_key: "org_id", path: "/organizations/:id" }] }
        end
      end
    end

    context "in parent class" do
      before { Foo::User.has_many :comments, class_name: "Post" }

      describe "associations accessor" do
        subject { Class.new(Foo::User).associations }

        describe "#object_id" do
          subject { super().object_id }
          it { is_expected.not_to eql Foo::User.associations.object_id }
        end

        describe "[:has_many]" do
          subject { super()[:has_many] }
          it { is_expected.to eql [{ name: :comments, data_key: :comments, default: [], class_name: "Post", path: "/comments", inverse_of: nil }] }
        end
      end
    end
  end

  context "handling associations without details" do
    before do
      Her::API.setup url: "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { [200, {}, { id: 1, name: "Tobias Fünke", comments: [{ comment: { id: 2, body: "Tobias, you blow hard!", user_id: 1 } }, { comment: { id: 3, body: "I wouldn't mind kissing that man between the cheeks, so to speak", user_id: 1 } }], role: { id: 1, body: "Admin" }, organization: { id: 1, name: "Bluth Company" }, organization_id: 1 }.to_json] }
          stub.get("/users/2") { [200, {}, { id: 2, name: "Lindsay Fünke", organization_id: 2 }.to_json] }
          stub.get("/users/1/comments") { [200, {}, [{ comment: { id: 4, body: "They're having a FIRESALE?" } }].to_json] }
          stub.get("/users/2/comments") { [200, {}, [{ comment: { id: 4, body: "They're having a FIRESALE?" } }, { comment: { id: 5, body: "Is this the tiny town from Footloose?" } }].to_json] }
          stub.get("/users/2/comments/5") { [200, {}, { comment: { id: 5, body: "Is this the tiny town from Footloose?" } }.to_json] }
          stub.get("/users/2/role") { [200, {}, { id: 2, body: "User" }.to_json] }
          stub.get("/users/1/role") { [200, {}, { id: 3, body: "User" }.to_json] }
          stub.get("/users/1/posts") { [200, {}, [{ id: 1, body: "blogging stuff", admin_id: 1 }].to_json] }
          stub.get("/organizations/1") { [200, {}, { organization:  { id: 1, name: "Bluth Company Foo" } }.to_json] }
          stub.post("/users") { [200, {}, { id: 5, name: "Mr. Krabs", comments: [{ comment: { id: 99, body: "Rodríguez, nasibisibusi?", user_id: 5 } }], role: { id: 1, body: "Admin" }, organization: { id: 3, name: "Krusty Krab" }, organization_id: 3 }.to_json] }
          stub.put("/users/5") { [200, {}, { id: 5, name: "Clancy Brown", comments: [{ comment: { id: 99, body: "Rodríguez, nasibisibusi?", user_id: 5 } }], role: { id: 1, body: "Admin" }, organization: { id: 3, name: "Krusty Krab" }, organization_id: 3 }.to_json] }
          stub.delete("/users/5") { [200, {}, { id: 5, name: "Clancy Brown", comments: [{ comment: { id: 99, body: "Rodríguez, nasibisibusi?", user_id: 5 } }], role: { id: 1, body: "Admin" }, organization: { id: 3, name: "Krusty Krab" }, organization_id: 3 }.to_json] }

          stub.get("/organizations/2") do |env|
            if env[:params]["admin"] == "true"
              [200, {}, { organization: { id: 2, name: "Bluth Company (admin)" } }.to_json]
            else
              [200, {}, { organization: { id: 2, name: "Bluth Company" } }.to_json]
            end
          end
        end
      end

      spawn_model "Foo::User" do
        has_many :comments, class_name: "Foo::Comment"
        has_one :role, class_name: "Foo::Role"
        belongs_to :organization, class_name: "Foo::Organization"
        has_many :posts, inverse_of: :admin
      end

      spawn_model "Foo::Comment" do
        belongs_to :user
        parse_root_in_json true
      end

      spawn_model "Foo::Post" do
        belongs_to :admin, class_name: "Foo::User"
      end

      spawn_model "Foo::Organization" do
        parse_root_in_json true
      end

      spawn_model "Foo::Role"

      @user_with_included_data = Foo::User.find(1)
      @user_without_included_data = Foo::User.find(2)
      @user_without_organization_and_not_persisted = Foo::User.new(organization_id: nil, name: "Katlin Fünke")
    end

    let(:user_with_included_data_after_create) { Foo::User.create }
    let(:user_with_included_data_after_save_existing) { Foo::User.save_existing(5, name: "Clancy Brown") }
    let(:user_with_included_data_after_destroy) { Foo::User.new(id: 5).destroy }
    let(:comment_without_included_parent_data) { Foo::Comment.new(id: 7, user_id: 1) }
    let(:new_user) { Foo::User.new }

    it "maps an array of included data through has_many" do
      expect(@user_with_included_data.comments.first).to be_a(Foo::Comment)
      expect(@user_with_included_data.comments.length).to eq(2)
      expect(@user_with_included_data.comments.first.id).to eq(2)
      expect(@user_with_included_data.comments.first.body).to eq("Tobias, you blow hard!")
    end

    it "does not refetch the parents models data if they have been fetched before" do
      expect(@user_with_included_data.comments.first.user.object_id).to eq(@user_with_included_data.object_id)
    end

    it "does fetch the parent models data only once" do
      expect(comment_without_included_parent_data.user.object_id).to eq(comment_without_included_parent_data.user.object_id)
    end

    it "does fetch the parent models data that was cached if called with parameters" do
      expect(comment_without_included_parent_data.user.object_id).not_to eq(comment_without_included_parent_data.user.where(a: 2).object_id)
    end

    it "uses the given inverse_of key to set the parent model" do
      expect(@user_with_included_data.posts.first.admin.object_id).to eq(@user_with_included_data.object_id)
    end

    it "doesn't attempt to fetch association data for a new resource" do
      expect(new_user.comments).to eq([])
      expect(new_user.role).to be_nil
      expect(new_user.organization).to be_nil
    end

    it "fetches data that was not included through has_many" do
      expect(@user_without_included_data.comments.first).to be_a(Foo::Comment)
      expect(@user_without_included_data.comments.length).to eq(2)
      expect(@user_without_included_data.comments.first.id).to eq(4)
      expect(@user_without_included_data.comments.first.body).to eq("They're having a FIRESALE?")
    end

    it "fetches has_many data even if it was included, only if called with parameters" do
      expect(@user_with_included_data.comments.where(foo_id: 1).length).to eq(1)
    end

    it "fetches data that was not included through has_many only once" do
      expect(@user_without_included_data.comments.first.object_id).to eq(@user_without_included_data.comments.first.object_id)
    end

    it "fetches data that was cached through has_many if called with parameters" do
      expect(@user_without_included_data.comments.first.object_id).not_to eq(@user_without_included_data.comments.where(foo_id: 1).first.object_id)
    end

    it "fetches data again after being reloaded" do
      expect { @user_without_included_data.comments.reload }.to change { @user_without_included_data.comments.first.object_id }
    end

    it "maps an array of included data through has_one" do
      expect(@user_with_included_data.role).to be_a(Foo::Role)
      expect(@user_with_included_data.role.object_id).to eq(@user_with_included_data.role.object_id)
      expect(@user_with_included_data.role.id).to eq(1)
      expect(@user_with_included_data.role.body).to eq("Admin")
    end

    it "fetches data that was not included through has_one" do
      expect(@user_without_included_data.role).to be_a(Foo::Role)
      expect(@user_without_included_data.role.id).to eq(2)
      expect(@user_without_included_data.role.body).to eq("User")
    end

    it "fetches has_one data even if it was included, only if called with parameters" do
      expect(@user_with_included_data.role.where(foo_id: 2).id).to eq(3)
    end

    it "maps an array of included data through belongs_to" do
      expect(@user_with_included_data.organization).to be_a(Foo::Organization)
      expect(@user_with_included_data.organization.id).to eq(1)
      expect(@user_with_included_data.organization.name).to eq("Bluth Company")
    end

    it "fetches data that was not included through belongs_to" do
      expect(@user_without_included_data.organization).to be_a(Foo::Organization)
      expect(@user_without_included_data.organization.id).to eq(2)
      expect(@user_without_included_data.organization.name).to eq("Bluth Company")
    end

    it "returns nil if the foreign key is nil" do
      expect(@user_without_organization_and_not_persisted.organization).to be_nil
    end

    it "fetches belongs_to data even if it was included, only if called with parameters" do
      expect(@user_with_included_data.organization.where(foo_id: 1).name).to eq("Bluth Company Foo")
    end

    it "can tell if it has a association" do
      expect(@user_without_included_data.has_association?(:unknown_association)).to be false
      expect(@user_without_included_data.has_association?(:organization)).to be true
    end

    it "fetches the resource corresponding to a named association" do
      expect(@user_without_included_data.get_association(:unknown_association)).to be_nil
      expect(@user_without_included_data.get_association(:organization).name).to eq("Bluth Company")
    end

    it "pass query string parameters when additional arguments are passed" do
      expect(@user_without_included_data.organization.where(admin: true).name).to eq("Bluth Company (admin)")
      expect(@user_without_included_data.organization.name).to eq("Bluth Company")
    end

    it "fetches data with the specified id when calling find" do
      comment = @user_without_included_data.comments.find(5)
      expect(comment).to be_a(Foo::Comment)
      expect(comment.id).to eq(5)
    end

    it "'s associations responds to #empty?" do
      expect(@user_without_included_data.organization.respond_to?(:empty?)).to be_truthy
      expect(@user_without_included_data.organization).not_to be_empty
    end

    it "includes has_many relationships in params by default" do
      params = @user_with_included_data.to_params
      expect(params[:comments]).to be_kind_of(Array)
      expect(params[:comments].length).to eq(2)
    end

    it "includes has_one relationship in params by default" do
      params = @user_with_included_data.to_params
      expect(params[:role]).to be_kind_of(Hash)
      expect(params[:role]).not_to be_empty
    end

    it "includes belongs_to relationship in params by default" do
      params = @user_with_included_data.to_params
      expect(params[:organization]).to be_kind_of(Hash)
      expect(params[:organization]).not_to be_empty
    end

    [:create, :save_existing, :destroy].each do |type|
      context "after #{type}" do
        let(:subject) { send("user_with_included_data_after_#{type}") }

        it "maps an array of included data through has_many" do
          expect(subject.comments.first).to be_a(Foo::Comment)
          expect(subject.comments.length).to eq(1)
          expect(subject.comments.first.id).to eq(99)
          expect(subject.comments.first.body).to eq("Rodríguez, nasibisibusi?")
        end

        it "maps an array of included data through has_one" do
          expect(subject.role).to be_a(Foo::Role)
          expect(subject.role.id).to eq(1)
          expect(subject.role.body).to eq("Admin")
        end
      end
    end
  end

  context "handling associations with details in active_model_serializers format" do
    before do
      Her::API.setup url: "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { [200, {}, { user: { id: 1, name: "Tobias Fünke", comments: [{ id: 2, body: "Tobias, you blow hard!", user_id: 1 }, { id: 3, body: "I wouldn't mind kissing that man between the cheeks, so to speak", user_id: 1 }], role: { id: 1, body: "Admin" }, organization: { id: 1, name: "Bluth Company" }, organization_id: 1 } }.to_json] }
          stub.get("/users/2") { [200, {}, { user: { id: 2, name: "Lindsay Fünke", organization_id: 1 } }.to_json] }
          stub.get("/users/1/comments") { [200, {}, { comments: [{ id: 4, body: "They're having a FIRESALE?" }] }.to_json] }
          stub.get("/users/2/comments") { [200, {}, { comments: [{ id: 4, body: "They're having a FIRESALE?" }, { id: 5, body: "Is this the tiny town from Footloose?" }] }.to_json] }
          stub.get("/users/2/comments/5") { [200, {}, { comment: { id: 5, body: "Is this the tiny town from Footloose?" } }.to_json] }
          stub.get("/organizations/1") { [200, {}, { organization:  { id: 1, name: "Bluth Company Foo" } }.to_json] }
        end
      end

      spawn_model "Foo::User" do
        parse_root_in_json true, format: :active_model_serializers
        has_many :comments, class_name: "Foo::Comment"
        has_one :role, class_name: "Foo::Role"
        belongs_to :organization, class_name: "Foo::Organization"
      end

      spawn_model "Foo::Role" do
        belongs_to :user
        parse_root_in_json true, format: :active_model_serializers
      end

      spawn_model "Foo::Comment" do
        belongs_to :user
        parse_root_in_json true, format: :active_model_serializers
      end

      spawn_model "Foo::Organization" do
        parse_root_in_json true, format: :active_model_serializers
      end

      @user_with_included_data = Foo::User.find(1)
      @user_without_included_data = Foo::User.find(2)
    end

    it "maps an array of included data through has_many" do
      expect(@user_with_included_data.comments.first).to be_a(Foo::Comment)
      expect(@user_with_included_data.comments.length).to eq(2)
      expect(@user_with_included_data.comments.first.id).to eq(2)
      expect(@user_with_included_data.comments.first.body).to eq("Tobias, you blow hard!")
    end

    it "does not refetch the parents models data if they have been fetched before" do
      expect(@user_with_included_data.comments.first.user.object_id).to eq(@user_with_included_data.object_id)
    end

    it "fetches data that was not included through has_many" do
      expect(@user_without_included_data.comments.first).to be_a(Foo::Comment)
      expect(@user_without_included_data.comments.length).to eq(2)
      expect(@user_without_included_data.comments.first.id).to eq(4)
      expect(@user_without_included_data.comments.first.body).to eq("They're having a FIRESALE?")
    end

    it "fetches has_many data even if it was included, only if called with parameters" do
      expect(@user_with_included_data.comments.where(foo_id: 1).length).to eq(1)
    end

    it "maps an array of included data through belongs_to" do
      expect(@user_with_included_data.organization).to be_a(Foo::Organization)
      expect(@user_with_included_data.organization.id).to eq(1)
      expect(@user_with_included_data.organization.name).to eq("Bluth Company")
    end

    it "fetches data that was not included through belongs_to" do
      expect(@user_without_included_data.organization).to be_a(Foo::Organization)
      expect(@user_without_included_data.organization.id).to eq(1)
      expect(@user_without_included_data.organization.name).to eq("Bluth Company Foo")
    end

    it "fetches belongs_to data even if it was included, only if called with parameters" do
      expect(@user_with_included_data.organization.where(foo_id: 1).name).to eq("Bluth Company Foo")
    end

    it "fetches data with the specified id when calling find" do
      comment = @user_without_included_data.comments.find(5)
      expect(comment).to be_a(Foo::Comment)
      expect(comment.id).to eq(5)
    end

    it "includes has_many relationships in params by default" do
      params = @user_with_included_data.to_params
      expect(params[:comments]).to be_kind_of(Array)
      expect(params[:comments].length).to eq(2)
    end

    it "includes has_one relationships in params by default" do
      params = @user_with_included_data.to_params
      expect(params[:role]).to be_kind_of(Hash)
      expect(params[:role]).not_to be_empty
    end

    it "includes belongs_to relationship in params by default" do
      params = @user_with_included_data.to_params
      expect(params[:organization]).to be_kind_of(Hash)
      expect(params[:organization]).not_to be_empty
    end
  end

  context "handling associations with details" do
    before do
      Her::API.setup url: "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { [200, {}, { id: 1, name: "Tobias Fünke", organization: { id: 1, name: "Bluth Company Inc." }, organization_id: 1 }.to_json] }
          stub.get("/users/4") { [200, {}, { id: 1, name: "Tobias Fünke", organization: { id: 1, name: "Bluth Company Inc." } }.to_json] }
          stub.get("/users/2") { [200, {}, { id: 2, name: "Lindsay Fünke", organization_id: 1 }.to_json] }
          stub.get("/users/3") { [200, {}, { id: 2, name: "Lindsay Fünke", company: nil }.to_json] }
          stub.get("/companies/1") { [200, {}, { id: 1, name: "Bluth Company" }.to_json] }
        end
      end

      spawn_model "Foo::User" do
        belongs_to :company, path: "/organizations/:id", foreign_key: :organization_id, data_key: :organization
      end

      spawn_model "Foo::Company"

      @user_with_included_data = Foo::User.find(1)
      @user_without_included_data = Foo::User.find(2)
      @user_with_included_nil_data = Foo::User.find(3)
      @user_with_included_data_but_no_fk = Foo::User.find(4)
    end

    it "maps an array of included data through belongs_to" do
      expect(@user_with_included_data.company).to be_a(Foo::Company)
      expect(@user_with_included_data.company.id).to eq(1)
      expect(@user_with_included_data.company.name).to eq("Bluth Company Inc.")
    end

    it "does not map included data if it’s nil" do
      expect(@user_with_included_nil_data.company).to be_nil
    end

    it "fetches data that was not included through belongs_to" do
      expect(@user_without_included_data.company).to be_a(Foo::Company)
      expect(@user_without_included_data.company.id).to eq(1)
      expect(@user_without_included_data.company.name).to eq("Bluth Company")
    end

    it "does not require foreugn key to have nested object" do
      expect(@user_with_included_data_but_no_fk.company.name).to eq("Bluth Company Inc.")
    end
  end

  context "object returned by the association method" do
    before do
      spawn_model "Foo::Role" do
        def present?
          "of_course"
        end
      end
      spawn_model "Foo::User" do
        has_one :role
      end
    end

    let(:associated_value) { Foo::Role.new }
    let(:user_with_role) do
      Foo::User.new.tap { |user| user.role = associated_value }
    end

    subject { user_with_role.role }

    it "doesnt mask the object's basic methods" do
      expect(subject.class).to eq(Foo::Role)
    end

    it "doesnt mask core methods like extend" do
      committer = Module.new
      subject.extend committer
      expect(associated_value).to be_kind_of committer
    end

    it "can return the association object" do
      expect(subject.association).to be_kind_of Her::Model::Associations::Association
    end

    it "still can call fetch via the association" do
      expect(subject.association.fetch).to eq associated_value
    end

    it "calls missing methods on associated value" do
      expect(subject.present?).to eq("of_course")
    end

    it "can use association methods like where" do
      expect(subject.where(role: "committer").association
        .params).to include :role
    end
  end

  context "building and creating association data" do
    before do
      spawn_model "Foo::Comment"
      spawn_model "Foo::User" do
        has_many :comments
      end
    end

    context "with #build" do
      it "takes the parent primary key" do
        @comment = Foo::User.new(id: 10).comments.build(body: "Hello!")
        expect(@comment.body).to eq("Hello!")
        expect(@comment.user_id).to eq(10)
      end
    end

    context "with #create" do
      before do
        Her::API.setup url: "https://api.example.com" do |builder|
          builder.use Her::Middleware::FirstLevelParseJSON
          builder.use Faraday::Request::UrlEncoded
          builder.adapter :test do |stub|
            stub.get("/users/10") { [200, {}, { id: 10 }.to_json] }
            stub.post("/comments") { |env| [200, {}, { id: 1, body: Faraday::Utils.parse_query(env[:body])["body"], user_id: Faraday::Utils.parse_query(env[:body])["user_id"].to_i }.to_json] }
          end
        end

        Foo::User.use_api Her::API.default_api
        Foo::Comment.use_api Her::API.default_api
      end

      it "takes the parent primary key and saves the resource" do
        @user = Foo::User.find(10)
        @comment = @user.comments.create(body: "Hello!")
        expect(@comment.id).to eq(1)
        expect(@comment.body).to eq("Hello!")
        expect(@comment.user_id).to eq(10)
        expect(@user.comments).to eq([@comment])
      end
    end

    context "with #new" do
      it "creates nested models from hash attibutes" do
        user = Foo::User.new(name: "vic", comments: [{ text: "hello" }])
        expect(user.comments.first.text).to eq("hello")
      end

      it "assigns nested models if given as already constructed objects" do
        bye = Foo::Comment.new(text: "goodbye")
        user = Foo::User.new(name: "vic", comments: [bye])
        expect(user.comments.first.text).to eq("goodbye")
      end
    end
  end
end
