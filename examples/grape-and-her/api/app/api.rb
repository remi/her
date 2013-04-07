class API < Grape::API
  content_type :json, "application/json; charset=UTF-8"
  format :json
  formatter :json, Grape::Formatter::Rabl
  use(Rack::Config) { |env| env['api.tilt.root'] = File.expand_path('../views',  __FILE__) }
  rescue_from :all

  resources :users do
    desc 'Return all users'
    get nil, :rabl => "users/index" do
      @users = User.all
    end

    desc 'Return a specific user'
    get ':id', :rabl => "users/show" do
      @user = User.find(params[:id])
    end

    desc 'Create a new user'
    post nil, :rabl => "users/show" do
      @user = User.new(params[:user])
      error!({ :errors => @user.errors.full_messages }, 400) unless @user.save
    end
  end

  resources :organizations do
    desc 'Return all organizations'
    get nil, :rabl => "organizations/index" do
      @organizations = Organization.all
    end

    desc 'Return a specific organization'
    get ':id', :rabl => "organizations/show" do
      @organization = Organization.find(params[:id])
    end

    desc 'Return all users for specific organization'
    get ':id/users', :rabl => "users/index" do
      organization = Organization.find(params[:id])
      @users = organization.users
    end

    desc 'Create a new organization'
    post nil, :rabl => "organizations/show" do
      @organization = Organization.new(params[:organization])
      error!({ :errors => @organization.errors.full_messages }, 400) unless @organization.save
    end
  end
end
