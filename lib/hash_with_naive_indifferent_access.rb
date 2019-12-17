class HashWithNaiveIndifferentAccess < Hash
  def [](key)
    super(key.to_s)
  end

  def []=(key, value)
    super(key.to_s, value)
  end

  def merge(other)
    super(other.transform_keys(&:to_s))
  end

  def merge!(other)
    super(other.transform_keys(&:to_s))
  end

  def include?(key)
    super(key.to_s)
  end
end
