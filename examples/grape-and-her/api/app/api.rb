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
end
