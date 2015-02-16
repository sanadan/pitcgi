require 'pitcgi/version'
require "yaml"
require "pathname"
require "tempfile"
require 'scrambled_eggs'

module Pitcgi
  NOT_TO_BE_INITIALIZED = "It is likely not to be initialized. Use '#{NAME} init'."
	ALREADY_SCRAMBLED = 'Already scrambled.'
  NOT_SCRAMBLED = 'Not scrambled.'
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
    self.save( profile )
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
      config = self.load_config
      ret = config["profile"]
    rescue Errno::ENOENT
      config = {}
      ret = ""
    end
		config["profile"] = name
		begin
      self.save_config( config )
    rescue Errno::ENOENT => e
      raise e, NOT_TO_BE_INITIALIZED
    end
    ret
	end
 
  # Scramble profile.
  def self.scramble
    config = self.load_config
    config_scrambled = self.get_scramble_config( config )
    if config_scrambled[ 'scrambled' ]
      raise( ALREADY_SCRAMBLED )
    end
    ScrambledEggs.new.scramble_file( @@profile )
    config_scrambled[ 'scrambled' ] = true
    config[ get_scramble_config_name( config ) ] = config_scrambled
    self.save_config( config )
    return
  end

  # Descramble profile.
  def self.descramble
    config = self.load_config
    config_scrambled = self.get_scramble_config( config )
    if !config_scrambled[ 'scrambled' ]
      raise( NOT_SCRAMBLED )
    end
    ScrambledEggs.new.descramble_file( @@profile )
    config_scrambled[ 'scrambled' ] = false
    config[ get_scramble_config_name( config ) ] = config_scrambled
    self.save_config( config )
    return
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
    config = self.load_config
		self.switch( config[ 'profile' ] )
		unless @@profile.exist?
			@@profile.open("w") {|f| f << {}.to_yaml }
			@@profile.chmod(0660)
      @@profile.chown(nil, 33)  # www-data
		end
    data = @@profile.binread
    if self.get_scramble_config( config )[ 'scrambled' ]
      data = ScrambledEggs.new.descramble( data )
    end
		YAML.load( data ) || {}
	end

  def self.save( profile )
    data = profile.to_yaml
    config = self.load_config
    self.switch( config[ 'profile' ] )
    if self.get_scramble_config( config )[ 'scrambled' ]
      data = ScrambledEggs.new.scramble( data )
    end
		# Not exist Pathname#write on Ruby 2.0.0.
    #@@profile.binwrite( data )
    IO.binwrite( @@profile, data )
  end

  def self.load_config
    YAML.load(@@config.read)
  end

  def self.save_config( config )
    # Not exist Pathname#write on Ruby 2.0.0.
    #@@config.write( config.to_yaml )
    IO.write( @@config, config.to_yaml )
  end

  def self.get_scramble_config( config )
    name = get_scramble_config_name( config )
    return config[ name ] ? config[ name ] : {}
  end
  
  def self.get_scramble_config_name( config )
    return config[ 'profile' ] + '_scramble'
  end
end

