module LiquidInterpolatable
  module Filters
    module ExtractDomain
      # Extract domain from a URL
      # Can optionally strip the 'www.' prefix
      #
      # Example usage:
      # {{ 'https://www.example.com/path' | extract_domain }} => 'www.example.com'
      # {{ 'https://www.example.com/path' | extract_domain: true }} => 'example.com'
      def extract_domain(input, strip_www = false)
        return input if input.blank?

        begin
          # Use Utils.normalize_uri for consistent parsing
          uri = Utils.normalize_uri(input.to_s)

          # We only care about HTTP/HTTPS/FTP
          return input unless ['http', 'https', 'ftp'].include?(uri.scheme)

          domain = uri.host
          return input unless domain

          if strip_www.to_s == 'true' || strip_www == true
            domain = domain.sub(/^www\./, '')
          end

          domain
        rescue URI::Error
          input
        end
      end
    end
  end
end

Liquid::Template.register_filter(LiquidInterpolatable::Filters::ExtractDomain)
