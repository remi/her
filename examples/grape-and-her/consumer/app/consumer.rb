class Consumer < Sinatra::Base
  configure do
    set :root, -> { File.expand_path("./") }
    set :views, -> { File.join(root, "app/views") }
    set :haml, :format => :html5, :attr_wrapper => '"', :ugly => true
  end

  configure :development do
    register Sinatra::Reloader
  end

  get '/users' do
    @users = User.all
    @user = User.new

    haml :'users/index'
  end

  post '/users' do
    @user = User.new(params[:user])

    if @user.save
      redirect to('/users')
    else
      haml :'users/index'
    end
  end
end
