class JsRegex
  #
  module Converter
    require_relative 'base'
    #
    # Template class implementation.
    #
    class TypeConverter < JsRegex::Converter::Base
      HEX_EXPANSION    = '[A-Fa-f0-9]'.freeze
      NONHEX_EXPANSION = '[^A-Fa-f0-9]'.freeze

      private

      def convert_data
        case subtype
        when :hex then HEX_EXPANSION
        when :nonhex then NONHEX_EXPANSION
        when :any, :digit, :nondigit, :word, :nonword, :space, :nonspace
          pass_through
        else
          warn_of_unsupported_feature
        end
      end
    end
  end
end
