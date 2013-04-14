module Her
  class Collection < ::Array
    attr_reader :metadata, :errors, :klass

    # @private
    def initialize(items=[], metadata={}, errors={}, klass=nil)
      super(items)
      @metadata = metadata
      @errors = errors
      @klass = klass
    end

    # @private
    def build(params={})
      raise Her::Errors::AssociationUnknownError if klass.nil?
      klass.new(params)
    end
  end
end
