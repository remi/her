class Consumer < Sinatra::Base
  configure do
    set :root, -> { File.expand_path("./") }
    set :views, -> { File.join(root, "app/views") }
    set :haml, :format => :html5, :attr_wrapper => '"', :ugly => true
  end

  configure :development do
    register Sinatra::Reloader
  end

  helpers Sprockets::Helpers

  before do
    $strio.truncate(0)
  end

  # GET /
  get '/' do
    haml :index
  end

  # GET /users
  get '/users' do
    @users = User.all
    @user = User.new

    haml :'users/index'
  end

  # GET /users/:id
  get '/users/:id' do
    @user = User.find(params[:id])
    haml :'users/show'
  end

  # GET /post
  post '/users' do
    @users = User.all
    @user = User.new(params[:user])

    if @user.save
      redirect to('/users')
    else
      haml :'users/index'
    end
  end

  # GET /organizations
  get '/organizations' do
    @organizations = Organization.all
    @organization = Organization.new

    haml :'organizations/index'
  end

  # GET /organizations/:id
  get '/organizations/:id' do
    @organization = Organization.find(params[:id])
    haml :'organizations/show'
  end

  # GET /post
  post '/organizations' do
    @organizations = Organization.all
    @organization = Organization.new(params[:organization])

    if @organization.save
      redirect to('/organizations')
    else
      haml :'organizations/index'
    end
  end
end
