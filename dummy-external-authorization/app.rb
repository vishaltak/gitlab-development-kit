require 'sinatra'
require 'json'
require 'yaml'

require './webrick_ssl'

def json(obj)
  obj.to_json
end

post '/', provides: :json do
  json_body = JSON.parse(request.body.read)
  puts "Called with: #{json_body.inspect}"

  email = json_body['user_identifier']
  label_name = json_body['project_classification_label']
  ldap_dn = json_body['user_ldap_dn']

  unless label_name
    return [400, json(reason: 'A label is required')]
  end

  unless email
    return [400, json(reason: 'An email is required')]
  end

  yaml_path = File.join(File.dirname(__FILE__), 'known_labels.yml')
  known_labels = YAML.load_file(yaml_path)

  unless label_info = known_labels.detect { |label_info| label_info.keys.first == label_name }
    return [404, json(reason: 'Unknown label')]
  end

  label = label_info.values.first
  authorized_emails = label['authorized_emails']
  authorized_dns = label['authorized_dns']
  if authorized_emails&.include?(email.strip.downcase) || authorized_dns&.include?(ldap_dn)
    return 200
  end

  [401, json(reason: "Not authorized to access '#{label_name}'")]
end
