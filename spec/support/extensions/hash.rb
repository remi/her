class Hash

  def to_json
    MultiJson.dump(self)
  end
end
