def load_current_resource
  include_recipe 'build-essential'
  chef_gem 'ruby-libvirt' do
    options '-- --with-libvirt-include=/usr/include/libvirt --with-libvirt-lib=/usr/lib'
    action :install
  end
  require 'libvirt'
  @current_resource = Chef::Resource::LibvirtSecret.new(new_resource.name)
  @libvirt = Libvirt_sock.new(new_resource.uri).sock
  @current_resource
end

action :define do
  require 'base64'
  require 'uuidtools'
  uuid = new_resource.uuid || ::UUIDTools::UUID.random_create
  begin
    new_secret_xml = <<-EOF
    <secret ephemeral='#{new_resource.ephemeral}' private='#{new_resource.private}'>
      <uuid>#{new_resource.uuid}</uuid>
      <usage type='#{new_resource.type}'>
        <name>#{new_resource.name}</name>
      </usage>
    </secret>
    EOF
    secret = @libvirt.define_secret_xml(new_secret_xml)
    secret.value = Base64.decode64(new_resource.value)
  rescue Libvirt::RetrieveError
    raise "ERROR"
  end
end
