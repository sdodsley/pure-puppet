
require 'puppet/purestorage'

Puppet::Type.type(:pure_volume).provide(:rest) do
    desc "Pure FlashArray volume provider using REST API"

    mk_resource_methods

    def array_host

    end

    def self.instances
        # TODO: Implement this?
        super()
    end

    def initialize(value={})
        super(value)
        @state_change = nil
    end

    def create
        @state_change = :create
    end

    def destroy
        @state_change = :destroy
    end

    def exists?
        Puppet.debug("#{self.class}.exists? #{resource[:name]} #{@property_hash}")
        @flasharray ||= FlashArray.new(resource[:purity_host], resource[:api_token])
        vol = @flasharray.get_volume(resource[:name])
        if vol.kind_of?(Array)
            return false
        else
            return vol["name"] == resource[:name]
        end
    end

    def flush
        Puppet.debug("#{self.class} Flushing pure_volume #{@state_change} #{@property_hash}")
        @flasharray ||= FlashArray.new(resource[:purity_host], resource[:api_token])
        if @state_change == :destroy
            @flasharray.destroy_volume(name)
            @flasharray.eradicate_volume(name)
        elsif @state_change == :create
            @flasharray.create_volume(name, {"size" => resource[:size]})
        else
            # The only thing that could change is size, if the target array changed
            # then exists? would fail and we get a :create
            @flasharray.update_volume(name, {"size" => resource[:size]})
        end
    end

end