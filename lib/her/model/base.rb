module Her
  module Model
    # This module includes basic functionnality to Her::Model
    module Base
      # Link a model with a Her::API object
      def uses_api(api) # {{{
        @her_api = api
      end # }}}
    end
  end
end
