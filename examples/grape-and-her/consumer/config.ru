require File.expand_path('../config/boot',  __FILE__)

map "/assets" do
  sprockets = Sprockets::Environment.new.tap do |s|
    s.append_path File.join(File.dirname(__FILE__), 'app', 'assets', 'stylesheets')
    s.append_path File.join(File.dirname(__FILE__), 'app', 'assets', 'images')

    Sprockets::Helpers.configure do |config|
      config.environment = s
      config.prefix = "/assets"
      config.digest = true
    end
  end

  run sprockets
end

map "/" do
  run Consumer
end
