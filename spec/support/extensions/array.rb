class Array
  def to_json
    MultiJson.dump(self)
  end
end
