# Easily test your SSL/TLS with RSpec.
module RspecSsltls
  # Utility class
  class Util
    def self.add_string(target, addition, separator = ', ')
      if target.nil?
        ' ' + addition
      else
        target + separator + addition
      end
    end

    def self.invalid_ssl_tls_protocol(protocol)
      protocol = Set.new + [protocol] unless protocol.respond_to?(:map)
      invalid_protocol =
        (protocol.map { |a| a.to_s } -
          OpenSSL::SSL::SSLContext::METHODS.map { |a| a.to_s })
      invalid_protocol.size > 0 ? invalid_protocol : nil
    end
  end
end
