require 'spec_helper'
require 'shared_behaviours/all_parsedfile_providers'
require'puppet_spec/files'

provider_class = Puppet::Type.type(:nagios_host).provider(:naginator)

describe provider_class do
  include PuppetSpec::Files

  before :each do
    @hostfile = tmpfile('nagios_host.cfg')
    @provider_class = provider_class
    @provider_class.initvars
    @provider_class.any_instance.stubs(:target).returns @hostfile
  end

  def mkhost(args)
    args[:target] = @hostfile
    resource = Puppet::Type.type(:nagios_host).new(args)
    host = @provider_class.new(resource)
    args.each do |k,v|
      next if k == :name
      host.send(k.to_s + "=", v)
    end
    host
  end

  def genhost(host)
    @provider_class.stubs(:filetype).returns(Puppet::Util::FileType::FileTypeRam)
    File.stubs(:chown)
    File.stubs(:chmod)
    Puppet::Util::SUIDManager.stubs(:asuser).yields
    host.flush
    @provider_class.target_object(@hostfile).read.gsub(/^\s+/m, '').gsub(/\s+/, ' ')
  end

  it_should_behave_like "all parsedfile providers", provider_class

  it "should be able to generate a host definition" do
    host = mkhost(:name          => "zippy",
                  :check_command => "check_zippy")
    genhost(host) == "define host {\ncheck_command check_zippy\nhost_name zippy\n}"
  end

  it "should be able to remove a check_command" do
    host = mkhost(:name          => "zippy",

                  :check_command => "check_zippy")
    genhost(host) == "define host {\ncheck_command check_zippy\nhost_name zippy\n}"

    host.check_command = :undef
    genhost(host) == "define host {\nhost_name zippy\n}"
  end
end
