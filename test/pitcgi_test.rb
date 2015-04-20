require "tmpdir"
require "pathname"

class Pathname
	@@tempname_number = 0
	def self.tempname(base=$0, dir=Dir.tmpdir)
		@@tempname_number += 1
		path = new(dir) + "#{File.basename(base)}.#{$$}.#{@@tempname_number}"
		at_exit do
			path.rmtree if path.exist?
		end
		path
	end
end

require File.dirname(__FILE__) + '/test_helper.rb'
require "test/unit"
ORG_DIR = Pitcgi::Directory.to_s.sub( /\/$/, '' ) + '.org'

def ps( command = nil )
  puts( command )
  system( command ) if command
end

class PitcgiTest < Test::Unit::TestCase
  self.test_order = :defined

  class << self
    def startup
      # Rename /etc/pitcgi if exist
      ps( "sudo mv #{Pitcgi::Directory} #{ORG_DIR}" )
    end

    def shutdown
      # Rename /etc/pitcgi.org if exist
      ps()
      ps( "sudo rm -rf #{Pitcgi::Directory}" )
      ps( "sudo mv #{ORG_DIR} #{Pitcgi::Directory}" )
    end
  end

	def test_load
		assert Pitcgi
	end

	def test_set_get
    ps( "pitcgi init" )

		Pitcgi.set("test", :data => {"username"=>"foo","password"=>"bar"})
		assert_equal "foo", Pitcgi.get("test")["username"]
		assert_equal "bar", Pitcgi.get("test")["password"]

		Pitcgi.set("test2", :data => {"username"=>"foo2","password"=>"bar2"})
		assert_equal "foo2", Pitcgi.get("test2")["username"]
		assert_equal "bar2", Pitcgi.get("test2")["password"]

		Pitcgi.set("test", :data => {"username"=>"foo3","password"=>"bar3"})
		assert_equal "foo3", Pitcgi.get("test")["username"]
		assert_equal "bar3", Pitcgi.get("test")["password"]

		assert_equal "foo4", Pitcgi.set("test", :data => {"username"=>"foo4","password"=>"bar4"})["username"]

    Pitcgi.set('test', :data => {'bool1'=>true, 'bool2'=>false})
    assert_equal true, Pitcgi.get('test')['bool1']
    assert_equal false, Pitcgi.get('test')['bool2']

    # Clear
    Pitcgi.set("test", :data => {})
    Pitcgi.set("test2", :data => {})
	end

	def test_editor
		ENV["EDITOR"] = nil
		assert_nothing_raised("When editor is not set.") do
			Pitcgi.set("test")
		end

		tst = Pathname.tempname
		exe = Pathname.tempname
		exe.open("w") do |f|
			f.puts <<-EOF.gsub(/^[\t ]+/, "")
				#!/usr/bin/env ruby

				File.open(ENV["TEST_FILE"], "w") do |f|
					f.puts ARGF.read
				end
			EOF
		end
		exe.chmod(0700)

		ENV["TEST_FILE"] = tst.to_s
		ENV["EDITOR"]    = exe.to_s
		Pitcgi.set("test")

		assert_nothing_raised do
			assert_equal({}, YAML.load_file(tst.to_s))
		end

		data = {
			"foo" => "0101",
			"bar" => "0202",
		}

		Pitcgi.set("test", :data => data)
		Pitcgi.set("test")

		assert_nothing_raised do
			assert_equal(data, YAML.load_file(tst.to_s))
		end

		# clear
		Pitcgi.set("test", :data => {})
		tst.open("w") {|f| }

		Pitcgi.get("test", :require => data)

		assert_nothing_raised do
			assert_equal(data, YAML.load_file(tst.to_s))
		end
	end

	def test_switch
		Pitcgi.switch("default")
		Pitcgi.set("test", :data => {"username"=>"foo5","password"=>"bar5"})
		assert_equal "foo5", Pitcgi.get("test")["username"]
		assert_equal "bar5", Pitcgi.get("test")["password"]

		r = Pitcgi.switch("profile2")
		assert_equal "default", r
		assert_equal( "profile2", Pitcgi.load_config[ "profile" ] )
		Pitcgi.set("test", :data => {"username"=>"foo2","password"=>"bar2"})
		assert_equal "foo2", Pitcgi.get("test")["username"]
		assert_equal "bar2", Pitcgi.get("test")["password"]

    assert_raise do
      Pitcgi.switch( 'pitcgi' )
    end
    assert_equal( 'foo2', Pitcgi.get( 'test' )[ 'username' ] )

		Pitcgi.switch("default")
		Pitcgi.set("test", :data => {"username"=>"foo6","password"=>"bar6"})
		assert_equal "foo6", Pitcgi.get("test")["username"]
		assert_equal "bar6", Pitcgi.get("test")["password"]

		# Clear
    Pitcgi.set("test", :data => {})
	end

  def test_scramble
    Pitcgi.set( 'test', :data => { 'username' => 'foo7', 'password' => 'bar7' } )
    path = Pathname( '/etc/pitcgi/default.yaml' )
    assert_nothing_raised do
      Pitcgi.descramble
    end
    src = path.binread
    assert_raise do
      Pitcgi.descramble
    end
    Pitcgi.scramble
    scrambled = path.binread
    assert_not_equal( src, scrambled )
    assert_raise do
      Pitcgi.scramble
    end
  end

  def test_access_scrambled
    username = 'foo8'
    password = 'bar8'
    Pitcgi.set( 'test', :data => { 'username' => username, 'password' => password } )
    Pitcgi.descramble
    assert_equal( Pitcgi.get( 'test' )[ 'username' ], username )
    assert_equal( Pitcgi.get( 'test' )[ 'password' ], password )
    Pitcgi.scramble
  end

  def test_access_mix_scrambled
    username = 'foo9'
    password = 'bar9'
    Pitcgi.set( 'test', :data => { 'username' => username, 'password' => password } )
    Pitcgi.descramble
    Pitcgi.switch( 'profile2' )
    username2 = 'foo10'
    password2 = 'bar10'
    Pitcgi.set( 'test2', :data => { 'username2' => username2, 'password2' => password2 } )

    Pitcgi.switch( 'default' )
    assert_equal( Pitcgi.get( 'test' )[ 'username' ], username )
    assert_equal( Pitcgi.get( 'test' )[ 'password' ], password )

    Pitcgi.switch( 'profile2' )
    assert_equal( Pitcgi.get( 'test2' )[ 'username2' ], username2 )
    assert_equal( Pitcgi.get( 'test2' )[ 'password2' ], password2 )
    Pitcgi.descramble
    assert_equal( Pitcgi.get( 'test2' )[ 'username2' ], username2 )
    assert_equal( Pitcgi.get( 'test2' )[ 'password2' ], password2 )

    Pitcgi.switch( 'default' )
    Pitcgi.scramble
    assert_equal( Pitcgi.get( 'test' )[ 'username' ], username )
    assert_equal( Pitcgi.get( 'test' )[ 'password' ], password )
  end
end

