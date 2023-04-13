module Restorm
  module JsonApi
    module Model
      def self.included(klass)
        klass.class_eval do
          include Restorm::Model

          [:parse_root_in_json, :include_root_in_json, :root_element, :primary_key].each do |method|
            define_method method do |*_|
              raise NoMethodError, "Restorm::JsonApi::Model does not support the #{method} configuration option"
            end
          end

          method_for :update, :patch

          @type = name.demodulize.tableize

          def self.parse(data)
            data.fetch(:attributes).merge(data.slice(:id))
          end

          def self.to_params(attributes, changes = {})
            request_data = { type: @type }.tap do |request_body|
              attrs = attributes.dup.symbolize_keys.tap do |filtered_attributes|
                if her_api.options[:send_only_modified_attributes]
                  filtered_attributes.slice! *changes.keys.map(&:to_sym)
                end
              end
              request_body[:id] = attrs.delete(:id) if attrs[:id]
              request_body[:attributes] = attrs
            end
            { data: request_data }
          end

          def self.type(type_name)
            @type = type_name.to_s
          end
        end
      end
    end
  end
end
