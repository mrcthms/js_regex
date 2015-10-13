class JsRegex
  module Converter
    #
    # Template class implementation.
    #
    class EscapeConverter < JsRegex::Converter::Base
      private

      def convert_data
        case subtype
        when :backslash, :dot, :form_feed, :hex, :interval_close,
             :interval_open, :literal, :newline, :one_or_more, :octal,
             :return, :space, :tab, :vertical_tab, :zero_or_more, :zero_or_one
          pass_through
        else
          # Backspace, Bell, HexWide, Control, Meta, MetaControl, ...
          warn_of_unsupported_feature
        end
      end
    end
  end
end