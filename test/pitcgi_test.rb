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

dir  = Pathname.tempname
dir.mkpath
#ENV["HOME"] = dir.to_s

require File.dirname(__FILE__) + '/test_helper.rb'

require "test/unit"
class PitcgiTest < Test::Unit::TestCase
	def test_load
		assert Pitcgi
	end

	def test_set_get
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
			f.puts <<-EOF.gsub(/^\t+/, "")
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
		assert_equal "profile2", Pitcgi.config["profile"]
		Pitcgi.set("test", :data => {"username"=>"foo2","password"=>"bar2"})
		assert_equal "foo2", Pitcgi.get("test")["username"]
		assert_equal "bar2", Pitcgi.get("test")["password"]

    # Clear
		Pitcgi.set("test", :data => {})
    
		Pitcgi.switch("default")
		Pitcgi.set("test", :data => {"username"=>"foo6","password"=>"bar6"})
		assert_equal "foo6", Pitcgi.get("test")["username"]
		assert_equal "bar6", Pitcgi.get("test")["password"]

		# Clear
    Pitcgi.set("test", :data => {})
	end
end
