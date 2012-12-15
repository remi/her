module Her
  class Collection < ::Array
    attr_reader :metadata, :errors

    # @private
    def initialize(items=[], metadata={}, errors={})
      super(items)
      @metadata = metadata
      @errors = errors
    end
  end
end
