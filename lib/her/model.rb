module Her
  module Model
    def self.included(base) # {{{
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end # }}}

    module InstanceMethods
    end

    module ClassMethods
      # Main wrapper around Her::API
      # @private
      def request(attrs={}) # {{{
        Her::API.request(attrs)
      end # }}}

      # Make a GET request and return the parsed JSON response
      def get(path, attrs={}) # {{{
        request attrs.merge(:path => path)
      end # }}}
    end
  end
end
