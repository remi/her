# encoding: utf-8

require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe Her::Model::Associations do
  context "setting associations without details" do
    before { spawn_model "Foo::User" }
    subject(:associations) { Foo::User.associations }

    describe "has_many associations" do
      subject { associations[:has_many] }

      context "single" do
        let(:comments_association) do
          {
            name: :comments,
            data_key: :comments,
            default: [],
            class_name: "Comment",
            path: "/comments",
            inverse_of: nil,
            autosave: true
          }
        end
        before { Foo::User.has_many :comments }

        it { is_expected.to eql [comments_association] }
      end

      context "multiple" do
        let(:comments_association) do
          {
            name: :comments,
            data_key: :comments,
            default: [],
            class_name: "Comment",
            path: "/comments",
            inverse_of: nil,
            autosave: true
          }
        end
        let(:posts_association) do
          {
            name: :posts,
            data_key: :posts,
            default: [],
            class_name: "Post",
            path: "/posts",
            inverse_of: nil,
            autosave: true
          }
        end
        before do
          Foo::User.has_many :comments
          Foo::User.has_many :posts
        end

        it { is_expected.to eql [comments_association, posts_association] }
      end
    end

    describe "has_one associations" do
      subject { associations[:has_one] }

      context "single" do
        let(:category_association) do
          {
            name: :category,
            data_key: :category,
            default: nil,
            class_name: "Category",
            path: "/category",
            autosave: true
          }
        end
        before { Foo::User.has_one :category }

        it { is_expected.to eql [category_association] }
      end

      context "multiple" do
        let(:category_association) do
          {
            name: :category,
            data_key: :category,
            default: nil,
            class_name: "Category",
            path: "/category",
            autosave: true
          }
        end
        let(:role_association) do
          {
            name: :role,
            data_key: :role,
            default: nil,
            class_name: "Role",
            path: "/role",
            autosave: true
          }
        end
        before do
          Foo::User.has_one :category
          Foo::User.has_one :role
        end

        it { is_expected.to eql [category_association, role_association] }
      end
    end

    describe "belongs_to associations" do
      subject { associations[:belongs_to] }

      context "single" do
        let(:organization_association) do
          {
            name: :organization,
            data_key: :organization,
            default: nil,
            class_name: "Organization",
            foreign_key: "organization_id",
            path: "/organizations/:id",
            autosave: true
          }
        end
        before { Foo::User.belongs_to :organization }

        it { is_expected.to eql [organization_association] }
      end

      context "multiple" do
        let(:organization_association) do
          {
            name: :organization,
            data_key: :organization,
            default: nil,
            class_name: "Organization",
            foreign_key: "organization_id",
            path: "/organizations/:id",
            autosave: true
          }
        end
        let(:family_association) do
          {
            name: :family,
            data_key: :family,
            default: nil,
            class_name: "Family",
            foreign_key: "family_id",
            path: "/families/:id",
            autosave: true
          }
        end
        before do
          Foo::User.belongs_to :organization
          Foo::User.belongs_to :family
        end

        it { is_expected.to eql [organization_association, family_association] }
      end
    end
  end

  context "setting associations with details" do
    before { spawn_model "Foo::User" }
    subject(:associations) { Foo::User.associations }

    context "in base class" do
      describe "has_many associations" do
        subject { associations[:has_many] }

        context "single" do
          let(:comments_association) do
            {
              name: :comments,
              data_key: :user_comments,
              default: {},
              class_name: "Post",
              path: "/comments",
              inverse_of: :admin,
              autosave: true
            }
          end
          before do
            Foo::User.has_many :comments, class_name: "Post",
                                          inverse_of: :admin,
                                          data_key: :user_comments,
                                          default: {}
          end

          it { is_expected.to eql [comments_association] }
        end
      end

      describe "has_one associations" do
        subject { associations[:has_one] }

        context "single" do
          let(:category_association) do
            {
              name: :category,
              data_key: :topic,
              default: nil,
              class_name: "Topic",
              foreign_key: "topic_id",
              path: "/category",
              autosave: true
            }
          end
          before do
            Foo::User.has_one :category, class_name: "Topic",
                                         foreign_key: "topic_id",
                                         data_key: :topic, default: nil
          end

          it { is_expected.to eql [category_association] }
        end
      end

      describe "belongs_to associations" do
        subject { associations[:belongs_to] }

        context "single" do
          let(:organization_association) do
            {
              name: :organization,
              data_key: :org,
              default: true,
              class_name: "Business",
              foreign_key: "org_id",
              path: "/organizations/:id",
              autosave: true
            }
          end
          before do
            Foo::User.belongs_to :organization, class_name: "Business",
                                                foreign_key: "org_id",
                                                data_key: :org,
                                                default: true
          end

          it { is_expected.to eql [organization_association] }
        end
      end
    end

    context "in parent class" do
      before { Foo::User.has_many :comments, class_name: "Post" }

      describe "associations accessor" do
        subject(:associations) { Class.new(Foo::User).associations }

        describe "#object_id" do
          subject { associations.object_id }
          it { is_expected.not_to eql Foo::User.associations.object_id }
        end

        describe "[:has_many]" do
          subject { associations[:has_many] }
          let(:association) do
            {
              name: :comments,
              data_key: :comments,
              default: [],
              class_name: "Post",
              path: "/comments",
              inverse_of: nil,
              autosave: true
            }
          end

          it { is_expected.to eql [association] }
        end
      end
    end
  end

  context "handling associations without details" do
    before do
      spawn_model "Foo::User" do
        has_many :comments, class_name: "Foo::Comment"
        has_one :role, class_name: "Foo::Role"
        belongs_to :organization, class_name: "Foo::Organization"
        has_many :posts, inverse_of: :admin
      end

      spawn_model "Foo::Comment" do
        collection_path "/users/:user_id/comments"
        belongs_to :user
        has_many :likes
        has_one :deletion
        parse_root_in_json true
      end

      spawn_model "Foo::Like" do
        collection_path "/users/:user_id/comments/:comment_id/likes"
      end

      spawn_model "Foo::Deletion" do
        collection_path "/users/:user_id/comments/:comment_id/deletion"
      end

      spawn_model "Foo::Post" do
        belongs_to :admin, class_name: "Foo::User"
      end

      spawn_model "Foo::Organization" do
        parse_root_in_json true
      end

      spawn_model "Foo::Role" do
        belongs_to :user
      end
    end

    context "with included data" do
      before(:context) do
        Her::API.setup url: "https://api.example.com" do |builder|
          builder.use Her::Middleware::FirstLevelParseJSON
          builder.use Faraday::Request::UrlEncoded
          builder.adapter :test do |stub|
            stub.get("/users/1") { [200, {}, { id: 1, name: "Tobias Fünke", comments: [{ comment: { id: 2, body: "Tobias, you blow hard!", user_id: 1 } }, { comment: { id: 3, body: "I wouldn't mind kissing that man between the cheeks, so to speak", user_id: 1 } }], role: { id: 1, body: "Admin" }, organization: { id: 1, name: "Bluth Company" }, organization_id: 1 }.to_json] }
            stub.get("/users/1/comments") { [200, {}, [{ comment: { id: 4, body: "They're having a FIRESALE?" } }].to_json] }
            stub.get("/users/1/role") { [200, {}, { id: 3, body: "User" }.to_json] }
            stub.get("/users/1/posts") { [200, {}, [{ id: 1, body: "blogging stuff", admin_id: 1 }].to_json] }
            stub.get("/organizations/1") { [200, {}, { organization: { id: 1, name: "Bluth Company Foo" } }.to_json] }
          end
        end
      end

      let(:user) { Foo::User.find(1) }
      let(:user_params) { user.to_params }

      it "maps an array of included data through has_many" do
        expect(user.comments.first).to be_a(Foo::Comment)
        expect(user.comments.length).to eq(2)
        expect(user.comments.first.id).to eq(2)
        expect(user.comments.first.body).to eq("Tobias, you blow hard!")
      end

      it "does not refetch the parents models data if they have been fetched before for a has_many" do
        expect(user.comments.first.user.object_id).to eq(user.object_id)
      end

      it "does not refetch the parents models data if they have been fetched before for a has_one" do
        expect(user.role.user.object_id).to eq(user.object_id)
      end

      it "uses the given inverse_of key to set the parent model" do
        expect(user.posts.first.admin.object_id).to eq(user.object_id)
      end

      it "fetches has_many data even if it was included, only if called with parameters" do
        expect(user.comments.where(foo_id: 1).length).to eq(1)
      end

      it "maps an array of included data through has_one" do
        expect(user.role).to be_a(Foo::Role)
        expect(user.role.object_id).to eq(user.role.object_id)
        expect(user.role.id).to eq(1)
        expect(user.role.body).to eq("Admin")
      end

      it "fetches has_one data even if it was included, only if called with parameters" do
        expect(user.role.where(foo_id: 2).id).to eq(3)
      end

      it "maps an array of included data through belongs_to" do
        expect(user.organization).to be_a(Foo::Organization)
        expect(user.organization.id).to eq(1)
        expect(user.organization.name).to eq("Bluth Company")
      end

      it "fetches belongs_to data even if it was included, only if called with parameters" do
        expect(user.organization.where(foo_id: 1).name).to eq("Bluth Company Foo")
      end

      it "includes has_many relationships in params by default" do
        expect(user_params[:comments]).to be_kind_of(Array)
        expect(user_params[:comments].length).to eq(2)
      end

      it "includes has_one relationship in params by default" do
        expect(user_params[:role]).to be_kind_of(Hash)
        expect(user_params[:role]).not_to be_empty
      end

      it "includes belongs_to relationship in params by default" do
        expect(user_params[:organization]).to be_kind_of(Hash)
        expect(user_params[:organization]).not_to be_empty
      end

      context 'and send_only_modified_attributes is true' do
        before do
          Her::API.default_api.options[:send_only_modified_attributes] = true
        end

        it 'does not include unmodified has_many relationships in params' do
          params = user.to_params
          expect(params[:comments]).to be_nil
        end

        it 'does not include an unmodified has_one relationship in params' do
          params = user.to_params
          expect(params[:role]).to be_nil
        end

        it 'does not include an unmodified belongs_to relationship in params' do
          params = user.to_params
          expect(params[:organization]).to be_nil
        end

        it 'includes a modified has_many relationship in params' do
          user.comments.last.body = 'Merry Christmas!'
          params = user.to_params
          expect(params[:comments]).to be_kind_of(Array)
          expect(params[:comments].length).to eq(1)
        end

        it 'includes a modified has_one relationship in params' do
          user.role.body = 'Guest'
          params = user.to_params
          expect(params[:role]).to be_kind_of(Hash)
          expect(params[:role]).not_to be_empty
        end

        it 'includes a modified belongs_to relationship in params' do
          user.organization.name = 'New Company'
          params = user.to_params
          expect(params[:organization]).to be_kind_of(Hash)
          expect(params[:organization]).not_to be_empty
        end
      end

      context 'and autosave as nil' do
        before do
          Foo::User.associations.values.each do |assocs|
            assocs.each do |assoc|
              assoc[:autosave] = nil
            end
          end
        end

        it 'does not include persisted has_many relationships in params' do
          params = user.to_params
          expect(params[:comments]).to be_nil
        end

        it 'does not include a persisted has_one relationship in params' do
          params = user.to_params
          expect(params[:role]).to be_nil
        end

        it 'does not include a persisted belongs_to relationship in params' do
          params = user.to_params
          expect(params[:organization]).to be_nil
        end

        it 'includes a new has_many relationship in params' do
          new = user.comments.build(body: 'Merry Christmas!')
          user.comments << new
          params = user.to_params
          expect(params[:comments]).to be_kind_of(Array)
          expect(params[:comments].length).to eq(1)
        end

        it 'includes a new has_one relationship in params' do
          user.role = Foo::Role.build(body: 'User')
          params = user.to_params
          expect(params[:role]).to be_kind_of(Hash)
          expect(params[:role]).not_to be_empty
        end

        it 'includes a new belongs_to relationship in params' do
          user.organization = Foo::Organization.build(name: 'Bluth Company')
          params = user.to_params
          expect(params[:organization]).to be_kind_of(Hash)
          expect(params[:organization]).not_to be_empty
        end
      end

      context 'and autosave as false' do
        before do
          Foo::User.associations.values.each do |assocs|
            assocs.each do |assoc|
              assoc[:autosave] = false
            end
          end
        end

        it 'does not include persisted has_many relationships in params' do
          params = user.to_params
          expect(params[:comments]).to be_nil
        end

        it 'does not include a persisted has_one relationship in params' do
          params = user.to_params
          expect(params[:role]).to be_nil
        end

        it 'does not include a persisted belongs_to relationship in params' do
          params = user.to_params
          expect(params[:organization]).to be_nil
        end

        it 'does not include a new has_many relationship in params' do
          new = user.comments.build(body: 'Merry Christmas!')
          user.comments << new
          params = user.to_params
          expect(params[:comments]).to be_nil
        end

        it 'does not include a new has_one relationship in params' do
          user.role = Foo::Role.build(body: 'User')
          params = user.to_params
          expect(params[:role]).to be_nil
        end

        it 'does not include a new belongs_to relationship in params' do
          user.organization = Foo::Organization.build(name: 'Bluth Company')
          params = user.to_params
          expect(params[:organization]).to be_nil
        end
      end
    end

    context "without included data" do
      before(:context) do
        Her::API.setup url: "https://api.example.com" do |builder|
          builder.use Her::Middleware::FirstLevelParseJSON
          builder.use Faraday::Request::UrlEncoded
          builder.adapter :test do |stub|
            stub.get("/users/2") { [200, {}, { id: 2, name: "Lindsay Fünke", organization_id: 2 }.to_json] }
            stub.get("/users/2/comments") { [200, {}, [{ comment: { id: 4, body: "They're having a FIRESALE?" } }, { comment: { id: 5, body: "Is this the tiny town from Footloose?" } }].to_json] }
            stub.get("/users/2/comments/5") { [200, {}, { comment: { id: 5, body: "Is this the tiny town from Footloose?" } }.to_json] }
            stub.get("/users/2/comments/5/likes") { [200, {}, [{ like: { id: 1, liker_id: 1 } }].to_json] }
            stub.get("/users/2/comments/5/deletion") { [200, {}, { deletion: { id: 1, deleter_id: 1 } }.to_json] }
            stub.get("/users/2/role") { [200, {}, { id: 2, body: "User" }.to_json] }
            stub.get("/organizations/1") { [200, {}, { organization: { id: 1, name: "Bluth Company Foo" } }.to_json] }
            stub.get("/organizations/2") do |env|
              if env[:params]["admin"] == "true"
                [200, {}, { organization: { id: 2, name: "Bluth Company (admin)" } }.to_json]
              else
                [200, {}, { organization: { id: 2, name: "Bluth Company" } }.to_json]
              end
            end
          end
        end
      end

      let(:user) { Foo::User.find(2) }

      it "does not refetch the parents models data if they have been fetched before for a has_many member" do
        expect(user.comments.find(5).user.object_id).to eq(user.object_id)
      end

      it "fetches data that was not included through has_many" do
        expect(user.comments.first).to be_a(Foo::Comment)
        expect(user.comments.length).to eq(2)
        expect(user.comments.first.id).to eq(4)
        expect(user.comments.first.body).to eq("They're having a FIRESALE?")
      end

      it "fetches data that was not included through has_many only once" do
        expect(user.comments.first.object_id).to eq(user.comments.first.object_id)
      end

      it "fetches data that was cached through has_many if called with parameters" do
        expect(user.comments.first.object_id).not_to eq(user.comments.where(foo_id: 1).first.object_id)
      end

      it "fetches data again after being reloaded" do
        expect { user.comments.reload }.to change { user.comments.first.object_id }
      end

      it "fetches data that was not included through has_one" do
        expect(user.role).to be_a(Foo::Role)
        expect(user.role.id).to eq(2)
        expect(user.role.body).to eq("User")
      end

      it "fetches data that was not included through belongs_to" do
        expect(user.organization).to be_a(Foo::Organization)
        expect(user.organization.id).to eq(2)
        expect(user.organization.name).to eq("Bluth Company")
      end

      it "can tell if it has a association" do
        expect(user.has_association?(:unknown_association)).to be false
        expect(user.has_association?(:organization)).to be true
      end

      it "fetches the resource corresponding to a named association" do
        expect(user.get_association(:unknown_association)).to be_nil
        expect(user.get_association(:organization).name).to eq("Bluth Company")
      end

      it "pass query string parameters when additional arguments are passed" do
        expect(user.organization.where(admin: true).name).to eq("Bluth Company (admin)")
        expect(user.organization.name).to eq("Bluth Company")
      end

      it "fetches data with the specified id when calling find" do
        comment = user.comments.find(5)
        expect(comment).to be_a(Foo::Comment)
        expect(comment.id).to eq(5)
      end

      it "uses nested path parameters from the parent when fetching a has_many" do
        like = user.comments.find(5).likes.first
        expect(like.request_path).to eq('/users/2/comments/5/likes')
      end

      it "uses nested path parameters from the parent when fetching a has_one" do
        deletion = user.comments.find(5).deletion
        expect(deletion.request_path).to eq('/users/2/comments/5/deletion')
      end

      it "'s associations responds to #empty?" do
        expect(user.organization.respond_to?(:empty?)).to be_truthy
        expect(user.organization).not_to be_empty
      end

      it "changes the belongs_to foreign key value when a new resource is assigned" do
        org1 = Foo::Organization.find(1)
        user.organization = org1
        expect(user.organization).to eq(org1)
        expect(user.changes).to eq('organization_id' => [2, 1])
      end

      it "nullifies the belongs_to foreign key value when a nil resource is assigned" do
        user.organization = nil
        expect(user.organization).to be_nil
        expect(user.changes).to eq('organization_id' => [2, nil])
      end
    end

    context "without included parent data" do
      before(:context) do
        Her::API.setup url: "https://api.example.com" do |builder|
          builder.use Her::Middleware::FirstLevelParseJSON
          builder.use Faraday::Request::UrlEncoded
        end
      end

      let(:comment) { Foo::Comment.new(id: 7, user_id: 1) }

      it "does fetch the parent models data only once" do
        expect(comment.user.object_id).to eq(comment.user.object_id)
      end

      it "does fetch the parent models data that was cached if called with parameters" do
        expect(comment.user.object_id).not_to eq(comment.user.where(a: 2).object_id)
      end
    end

    context "when resource is new" do
      let(:new_user) { Foo::User.new }

      it "doesn't attempt to fetch association data" do
        expect(new_user.comments).to eq([])
        expect(new_user.role).to be_nil
        expect(new_user.organization).to be_nil
      end
    end

    context "when foreign_key is nil" do
      before do
        spawn_model "Foo::User" do
          belongs_to :organization, class_name: "Foo::Organization"
        end

        spawn_model "Foo::Organization" do
          parse_root_in_json true
        end
      end

      let(:user) { Foo::User.new(organization_id: nil, name: "Katlin Fünke") }

      it "returns nil" do
        expect(user.organization).to be_nil
      end
    end

    context "after" do
      before(:context) do
        Her::API.setup url: "https://api.example.com" do |builder|
          builder.use Her::Middleware::FirstLevelParseJSON
          builder.use Faraday::Request::UrlEncoded
          builder.adapter :test do |stub|
            stub.post("/users") { [200, {}, { id: 5, name: "Mr. Krabs", comments: [{ comment: { id: 99, body: "Rodríguez, nasibisibusi?", user_id: 5 } }], role: { id: 1, body: "Admin" }, organization: { id: 3, name: "Krusty Krab" }, organization_id: 3 }.to_json] }
            stub.put("/users/5") { [200, {}, { id: 5, name: "Clancy Brown", comments: [{ comment: { id: 99, body: "Rodríguez, nasibisibusi?", user_id: 5 } }], role: { id: 1, body: "Admin" }, organization: { id: 3, name: "Krusty Krab" }, organization_id: 3 }.to_json] }
            stub.delete("/users/5") { [200, {}, { id: 5, name: "Clancy Brown", comments: [{ comment: { id: 99, body: "Rodríguez, nasibisibusi?", user_id: 5 } }], role: { id: 1, body: "Admin" }, organization: { id: 3, name: "Krusty Krab" }, organization_id: 3 }.to_json] }
          end
        end
      end

      let(:user_after_create) { Foo::User.create }
      let(:user_after_save_existing) { Foo::User.save_existing(5, name: "Clancy Brown") }
      let(:user_after_destroy) { Foo::User.new(id: 5).destroy }

      [:create, :save_existing, :destroy].each do |type|
        context "after #{type}" do
          let(:subject) { send("user_after_#{type}") }

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
  end

  context "handling associations with details in active_model_serializers format" do
    before do
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
    end

    context "with included data" do
      before(:context) do
        Her::API.setup url: "https://api.example.com" do |builder|
          builder.use Her::Middleware::FirstLevelParseJSON
          builder.use Faraday::Request::UrlEncoded
          builder.adapter :test do |stub|
            stub.get("/users/1") { [200, {}, { user: { id: 1, name: "Tobias Fünke", comments: [{ id: 2, body: "Tobias, you blow hard!", user_id: 1 }, { id: 3, body: "I wouldn't mind kissing that man between the cheeks, so to speak", user_id: 1 }], role: { id: 1, body: "Admin" }, organization: { id: 1, name: "Bluth Company" }, organization_id: 1 } }.to_json] }
            stub.get("/users/1/comments") { [200, {}, { comments: [{ id: 4, body: "They're having a FIRESALE?" }] }.to_json] }
            stub.get("/organizations/1") { [200, {}, { organization: { id: 1, name: "Bluth Company Foo" } }.to_json] }
          end
        end
      end

      let(:user) { Foo::User.find(1) }
      let(:user_params) { user.to_params }

      it "maps an array of included data through has_many" do
        expect(user.comments.first).to be_a(Foo::Comment)
        expect(user.comments.length).to eq(2)
        expect(user.comments.first.id).to eq(2)
        expect(user.comments.first.body).to eq("Tobias, you blow hard!")
      end

      it "does not refetch the parents models data if they have been fetched before" do
        expect(user.comments.first.user.object_id).to eq(user.object_id)
      end

      it "fetches has_many data even if it was included, only if called with parameters" do
        expect(user.comments.where(foo_id: 1).length).to eq(1)
      end

      it "maps an array of included data through belongs_to" do
        expect(user.organization).to be_a(Foo::Organization)
        expect(user.organization.id).to eq(1)
        expect(user.organization.name).to eq("Bluth Company")
      end

      it "fetches belongs_to data even if it was included, only if called with parameters" do
        expect(user.organization.where(foo_id: 1).name).to eq("Bluth Company Foo")
      end

      it "includes has_many relationships in params by default" do
        expect(user_params[:comments]).to be_kind_of(Array)
        expect(user_params[:comments].length).to eq(2)
      end

      it "includes has_one relationships in params by default" do
        expect(user_params[:role]).to be_kind_of(Hash)
        expect(user_params[:role]).not_to be_empty
      end

      it "includes belongs_to relationship in params by default" do
        expect(user_params[:organization]).to be_kind_of(Hash)
        expect(user_params[:organization]).not_to be_empty
      end
    end

    context "without included data" do
      before(:context) do
        Her::API.setup url: "https://api.example.com" do |builder|
          builder.use Her::Middleware::FirstLevelParseJSON
          builder.use Faraday::Request::UrlEncoded
          builder.adapter :test do |stub|
            stub.get("/users/2") { [200, {}, { user: { id: 2, name: "Lindsay Fünke", organization_id: 1 } }.to_json] }
            stub.get("/users/2/comments") { [200, {}, { comments: [{ id: 4, body: "They're having a FIRESALE?" }, { id: 5, body: "Is this the tiny town from Footloose?" }] }.to_json] }
            stub.get("/users/2/comments/5") { [200, {}, { comment: { id: 5, body: "Is this the tiny town from Footloose?" } }.to_json] }
            stub.get("/organizations/1") { [200, {}, { organization: { id: 1, name: "Bluth Company Foo" } }.to_json] }
          end
        end
      end

      let(:user) { Foo::User.find(2) }

      it "fetches data that was not included through has_many" do
        expect(user.comments.first).to be_a(Foo::Comment)
        expect(user.comments.length).to eq(2)
        expect(user.comments.first.id).to eq(4)
        expect(user.comments.first.body).to eq("They're having a FIRESALE?")
      end

      it "fetches data that was not included through belongs_to" do
        expect(user.organization).to be_a(Foo::Organization)
        expect(user.organization.id).to eq(1)
        expect(user.organization.name).to eq("Bluth Company Foo")
      end

      it "fetches data with the specified id when calling find" do
        comment = user.comments.find(5)
        expect(comment).to be_a(Foo::Comment)
        expect(comment.id).to eq(5)
      end
    end
  end

  context "handling associations with details" do
    before do
      spawn_model "Foo::User" do
        belongs_to :company, path: "/organizations/:id", foreign_key: :organization_id, data_key: :organization
      end

      spawn_model "Foo::Company"
    end

    context "with included data" do
      before(:context) do
        Her::API.setup url: "https://api.example.com" do |builder|
          builder.use Her::Middleware::FirstLevelParseJSON
          builder.use Faraday::Request::UrlEncoded
          builder.adapter :test do |stub|
            stub.get("/users/1") { [200, {}, { id: 1, name: "Tobias Fünke", organization: { id: 1, name: "Bluth Company Inc." }, organization_id: 1 }.to_json] }
            stub.get("/users/4") { [200, {}, { id: 1, name: "Tobias Fünke", organization: { id: 1, name: "Bluth Company Inc." } }.to_json] }
            stub.get("/users/3") { [200, {}, { id: 2, name: "Lindsay Fünke", company: nil }.to_json] }
            stub.get("/companies/1") { [200, {}, { id: 1, name: "Bluth Company" }.to_json] }
          end
        end
      end

      let(:user) { Foo::User.find(1) }

      it "maps an array of included data through belongs_to" do
        expect(user.company).to be_a(Foo::Company)
        expect(user.company.id).to eq(1)
        expect(user.company.name).to eq("Bluth Company Inc.")
      end

      context "when included data is nil" do
        let(:user) { Foo::User.find(3) }

        it "does not map included data" do
          expect(user.company).to be_nil
        end
      end

      context "when included data has no foreign_key" do
        let(:user) { Foo::User.find(4) }

        it "maps included data anyway" do
          expect(user.company.name).to eq("Bluth Company Inc.")
        end
      end
    end

    context "without included data" do
      before(:context) do
        Her::API.setup url: "https://api.example.com" do |builder|
          builder.use Her::Middleware::FirstLevelParseJSON
          builder.use Faraday::Request::UrlEncoded
          builder.adapter :test do |stub|
            stub.get("/users/2") { [200, {}, { id: 2, name: "Lindsay Fünke", organization_id: 1 }.to_json] }
            stub.get("/companies/1") { [200, {}, { id: 1, name: "Bluth Company" }.to_json] }
          end
        end
      end

      let(:user) { Foo::User.find(2) }

      it "fetches data that was not included through belongs_to" do
        expect(user.company).to be_a(Foo::Company)
        expect(user.company.id).to eq(1)
        expect(user.company.name).to eq("Bluth Company")
      end
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
      Her::API.setup url: "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/10/comments/new?body=Hello") { [200, {}, { id: nil, body: "Hello" }.to_json] }
        end
      end

      spawn_model "Foo::Like" do
        collection_path "/users/:user_id/comments/:comment_id/likes"
      end
      spawn_model "Foo::Comment" do
        collection_path "/users/:user_id/comments"
        has_many :likes
      end
      spawn_model "Foo::User" do
        has_many :comments
      end
    end

    context "with #build" do
      let(:comment) { Foo::User.new(id: 10).comments.build(body: "Hello!") }

      it "takes the parent primary key" do
        expect(comment.body).to eq("Hello!")
        expect(comment.user_id).to eq(10)
      end

      it "caches the parent record when the inverse if present" do
        Foo::Comment.belongs_to :user
        @user = Foo::User.new(id: 10)
        @comment = @user.comments.build
        expect(@comment.user.object_id).to eq(@user.object_id)
      end

      it "does not cache the parent resource when inverse is missing" do
        @user = Foo::User.new(id: 10)
        @comment = @user.comments.build
        expect(@comment.respond_to?(:user)).to be_falsey
      end

      it "uses nested path parameters from the parent when new object isn't requested" do
        @like = Foo::User.new(:id => 10).comments.build(:id => 20).likes.build
        expect(@like.request_path).to eq("/users/10/comments/20/likes")
      end

      it "uses nested path parameters from the parent when new object is requested" do
        Foo::Comment.request_new_object_on_build true
        @comment = Foo::User.new(:id => 10).comments.build(:body => "Hello")
        expect(@comment.request_path).to eq("/users/10/comments")
      end
    end

    context "with #create" do
      let(:user) { Foo::User.find(10) }
      let(:comment) { user.comments.create(body: "Hello!") }

      before do
        Her::API.setup url: "https://api.example.com" do |builder|
          builder.use Her::Middleware::FirstLevelParseJSON
          builder.use Faraday::Request::UrlEncoded
          builder.adapter :test do |stub|
            stub.get("/users/10") { [200, {}, { id: 10 }.to_json] }
            stub.post("/users/10/comments") { |env| [200, {}, { id: 1, body: Faraday::Utils.parse_query(env[:body])["body"], user_id: Faraday::Utils.parse_query(env[:body])["user_id"].to_i }.to_json] }
          end
        end

        Foo::User.use_api Her::API.default_api
        Foo::Comment.use_api Her::API.default_api
      end

      it "takes the parent primary key and saves the resource" do
        expect(comment.id).to eq(1)
        expect(comment.body).to eq("Hello!")
        expect(comment.user_id).to eq(10)
        expect(user.comments).to eq([comment])
      end
    end

    context "with #new" do
      let(:user) { Foo::User.new(name: "vic", comments: [comment]) }

      context "using hash attributes" do
        let(:comment) { { text: "hello" } }

        it "assigns nested models" do
          expect(user.comments.first.text).to eq("hello")
        end
      end

      context "using constructed objects" do
        let(:comment) { Foo::Comment.new(text: "goodbye") }

        it "assigns nested models" do
          expect(user.comments.first.text).to eq("goodbye")
        end
      end
    end
  end
end
