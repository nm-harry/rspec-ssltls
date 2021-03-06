require 'rspec_ssltls'
require 'uri'
require 'time'

RSpec::Matchers.define :have_certificate do
  match do |dest|
    @chain_string  ||= ''
    @result_string ||= ''
    @chain_number  ||= 0
    uri = URI.parse('https://' + dest)
    socket = RspecSsltls::Util.open_socket(uri, proxy: @proxy)
    ssl_context = OpenSSL::SSL::SSLContext.new
    ssl_context.verify_mode = @verify_mode if @verify_mode
    ssl_context.cert_store  = @cert_store  if @cert_store
    ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ssl_context)
    ssl_socket.sync_close = true
    ssl_socket.hostname = uri.host
    ssl_socket.connect
    if ssl_socket.peer_cert_chain
      @peer_cert = ssl_socket.peer_cert_chain[@chain_number]
    end
    @verify_result = ssl_socket.verify_result
    ssl_socket.close
    @peer_cert ? valid_cert? && verified_cert? : false
  end

  chain :subject do |id|
    id_chain(:subject, id)
  end

  chain :issuer do |id|
    id_chain(:issuer, id)
  end

  chain :chain do |n|
    @chain_number = n
    @chain_string =
      RspecSsltls::Util.add_string(@chain_string, "chain[#{n}]")
  end

  chain :verified do
    @verify_mode = OpenSSL::SSL::VERIFY_PEER
    @cert_store = OpenSSL::X509::Store.new
    @cert_store.set_default_paths
    @chain_string =
      RspecSsltls::Util.add_string(@chain_string, 'verified')
  end

  chain :verified_with do |c|
    @verify_mode = OpenSSL::SSL::VERIFY_PEER
    @cert_store = OpenSSL::X509::Store.new
    @cert_store.add_file(c)
    @chain_string =
      RspecSsltls::Util.add_string(@chain_string, "verified with #{c}")
  end

  chain :valid_at do |t|
    @chain_string =
      RspecSsltls::Util.add_string(@chain_string, "valid at #{t}")
    @t1 = t
    @t2 = t
  end

  chain :valid_in do |t1, t2|
    @chain_string = RspecSsltls::Util
      .add_string(@chain_string, "valid in #{t1} - #{t2}")
    @t1 = t1
    @t2 = t2
  end

  chain :signature_algorithm do |s|
    @chain_string =
      RspecSsltls::Util.add_string(@chain_string, "signed with #{s}")
    @signature_algorithm = s
  end

  chain :via_proxy do |proxy|
    @proxy = proxy
  end

  def valid_cert?
    @result_cert = {}
    @result_cert.merge!(subject: valid_identifier?(:subject, @subject))
    @result_cert.merge!(issuer:  valid_identifier?(:issuer, @issuer))
    @result_cert.merge!(valid_in: valid_in?)
    @result_cert.merge!(signature_algorithm: valid_signature_algolithm?)
    @result_cert.values.all? { |r| r == true }
  end

  def valid_identifier?(kind, id)
    return true unless id
    invalid = false
    id.each_pair do |k, v|
      value = cert_value(kind, k)
      next if value == v
      @result_string += "  expected: #{k}=\"#{v}\"\n"
      @result_string += "  actual:   #{k}=\"#{value}\"\n"
      invalid = true
    end
    invalid ? false : true
  end

  def cert_value(kind, key)
    values = @peer_cert.send(kind).to_a.select do |k, _, _|
      k.to_s == key.to_s
    end
    values.first ? values.first[1] : ''
  end

  def id_chain(key, id)
    fail 'Argument Error. Needs hash arguments' unless
      id.respond_to?(:each_pair)

    instance_variable_set("@#{key}", id)
    kv = id.each_pair.map { |k, v| "#{k}=\"#{v}\"" }.join(', ')
    @chain_string =
      RspecSsltls::Util.add_string(@chain_string, "#{key} #{kv}", ' ')
  end

  def verified_cert?
    return true if @verify_mode.nil?
    @result_string += "  expected: verified\n"
    if @verify_result == OpenSSL::X509::V_OK
      @result_string += "  actual:   verified\n"
    else
      @result_string += "  actual:   unverified(errorcode: #{@verify_result})\n"
    end
    @verify_result == OpenSSL::X509::V_OK
  end

  def valid_in?
    return true unless @t1 && @t2
    fail 'Input time range is incorrect' if @t2 < @t1
    parse_time

    if @t1 == @t2
      @result_string += "  expected: valid in #{@t1} .. #{@t2}\n"
    else
      @result_string += "  expected: valid at #{@t1}\n"
    end
    @result_string += "  actual:   valid in #{@peer_cert.not_before}"
    @result_string += ".. #{@peer_cert.not_after}\n"

    (@peer_cert.not_before..@peer_cert.not_after).cover?(@t1) &&
      (@peer_cert.not_before..@peer_cert.not_after).cover?(@t2)
  end

  def valid_signature_algolithm?
    return true unless @signature_algorithm
    @result_string += "  expected: signed with #{@signature_algorithm}\n"
    @result_string +=
      "  actual:   signed with #{@peer_cert.signature_algorithm}\n"
    @signature_algorithm == @peer_cert.signature_algorithm
  end

  def parse_time
    @t1 = Time.parse(@t1) unless @t1.respond_to?(:getutc)
    @t2 = Time.parse(@t2) unless @t2.respond_to?(:getutc)
  end

  description do
    "have a certificate#{@chain_string}"
  end

  failure_message do
    s = "expected to have a certificate#{@chain_string}, but did not."
    s + "\n#{@result_string}"
  end

  failure_message_when_negated do
    s = "expected not to have a certificate#{@chain_string}, but did."
    s + "\n#{@result_string}"
      .sub(/(expected:)/, 'expected not:')
      .sub(/(actual:)/,   'actual:    ')
  end
end
