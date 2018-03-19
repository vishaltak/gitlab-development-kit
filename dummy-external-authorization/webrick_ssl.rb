require 'webrick/https'
require 'pry'
module Sinatra
  class Application
    def self.run!
      store = OpenSSL::X509::Store.new
      store.add_file(File.join(File.dirname(__FILE__), 'keys', 'ca', 'ca.pem'))

      server_options = {
        SSLVerifyClient: OpenSSL::SSL::VERIFY_PEER|OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT,
        SSLCertificateStore: store,
        SSLEnable: true,
        SSLCertName: [['CN', 'localhost', OpenSSL::ASN1::PRINTABLESTRING]],
        Port: 4567,
        SSLVerifyCallback: lambda do |succeeded, ssl_context|
          puts "ERROR #{ssl_context.error}: #{ssl_context.error_string}"

          succeeded
        end
      }

      Rack::Handler::WEBrick.run self, server_options do |server|
        [:INT, :TERM].each { |sig| trap(sig) { server.stop } }
        server.threaded = settings.threaded if server.respond_to? :threaded=
        set :running, true
      end
    end
  end
end
