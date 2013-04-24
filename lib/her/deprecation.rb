module Her
  # @private
  module Deprecation
    extend ActiveSupport::Concern

    def self.replace_method!(old, new, object, *args)
      warn! "The `#{old}` method is deprecated and may be removed soon. Please update your code with `#{new}` instead (line: #{line})."
      object.send(new, *args)
    end

    def self.warn!(message)
      warn("DEPRECATION WARNING! " + message)
    end
  end
end
