require 'pitcgi/version'
require "yaml"
require "pathname"
require "tempfile"

module Pitcgi
  NAME = 'pitcgi'
  NOT_TO_BE_INITIALIZED = "It is likely not to be initialized. Use '#{NAME} init'."
	Directory = Pathname.new("/etc/pitcgi").expand_path
	@@config  = Directory + "pitcgi.yaml"
	@@profile = Directory + "default.yaml"

	# Set _name_ setting to current profile.
	# If not _opts_ specified, this opens $EDITOR with current profile setting.
	# If `data` specified, this just sets it to current profile.
	# If `config` specified, this opens $EDITOR with merged hash with specified
  # hash and current profile.
	def self.set(name, opts={})
		profile = self.load
		if opts.key?(:data)
			result = opts[:data]
		else
			if ENV["EDITOR"].nil? || !$stdout.tty?
				return {}
			end
			c = (opts[:config] || self.get(name)).to_yaml
			t = Tempfile.new("pitcgi")
			t << c
			t.close
			system(ENV["EDITOR"], t.path)
			t.open
			result = t.read
			if result == c
				warn "No Changes"
				return profile[name]
			end
			result = YAML.load(result)
		end
		profile[name] = result
		@@profile.open("w") {|f| YAML.dump(profile, f) }
		result
	end

	# Get _name_ setting from current profile.
	# If not _opts_ specified, this just returns setting from current profile.
	# If _require_ specified, check keys on setting and open $EDITOR.
	def self.get(name, opts={})
		ret = self.load[name] || {}
		if opts[:require]
			unless opts[:require].keys.all? {|k| ret[k] != nil }
				ret = opts[:require].update(ret)
				ret = self.set(name, :config => ret)
			end
		end
		ret || {"username"=>"", "password"=>""}
	end

	# Switch to current profile to _name_.
	# Profile is set of settings. You can switch some settings using profile.
	def self.switch(name, opts={})
		@@profile = Directory + "#{name}.yaml"
		begin
      config = self.config
      ret = config["profile"]
    rescue Errno::ENOENT
      config = {}
      ret = ""
    end
		config["profile"] = name
		begin
      @@config.open("w") {|f| f << config.to_yaml }
    rescue Errno::ENOENT => e
      raise e, NOT_TO_BE_INITIALIZED
    end
    ret
	end

	protected
	def self.load
    unless Directory.exist?
      begin
		    Directory.mkpath
		    Directory.chmod 0770
        Directory.chown(nil, 33)  # www-data
      rescue Errno::EACCES => e
        raise e, NOT_TO_BE_INITIALIZED
      end
    end
		unless @@config.exist?
			@@config.open("w") {|f| f << {"profile"=>"default"}.to_yaml }
			@@config.chmod(0660)
      @@config.chown(nil, 33)  # www-data
    end
		self.switch(self.config["profile"])
		unless @@profile.exist?
			@@profile.open("w") {|f| f << {}.to_yaml }
			@@profile.chmod(0660)
      @@profile.chown(nil, 33)  # www-data
		end
		YAML.load(@@profile.read) || {}
	end

	def self.config
#		begin
      YAML.load(@@config.read)
#    rescue Errno::ENOENT => e
#      raise e, NOT_TO_BE_INITIALIZED
#    end
  end
end

