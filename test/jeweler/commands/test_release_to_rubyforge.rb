require 'test_helper'

class Jeweler
  module Commands
    class TestReleaseToRubyforge < Test::Unit::TestCase
      subject { Jeweler::Commands::ReleaseToRubyforge.new }

      rubyforge_command_context "rubyforge_project is defined in gemspec and package exists on rubyforge" do
        setup do
          stub(@rubyforge).configure
          stub(@rubyforge).login
          stub(@rubyforge).add_release("MyRubyForgeProjectName", "zomg", "1.2.3", "pkg/zomg-1.2.3.gem")

          stub(@gemspec).description {"The zomg gem rocks."}
          stub(@gemspec).rubyforge_project {"MyRubyForgeProjectName"}
          stub(@gemspec).name {"zomg"}
          
          stub(@gemspec_helper).write
          stub(@gemspec_helper).gem_path {'pkg/zomg-1.2.3.gem'}
          stub(@gemspec_helper).update_version('1.2.3')

          @command.repo           = @repo
          @command.version        = '1.2.3'

          @command.run
        end

        should "configure" do
          assert_received(@rubyforge) {|rubyforge| rubyforge.configure }
        end

        should "login" do
          assert_received(@rubyforge) {|rubyforge| rubyforge.login }
        end

        should "set release notes" do
          assert_equal "The zomg gem rocks.", @rubyforge.userconfig["release_notes"]
        end
        
        should "set preformatted to true" do
          assert_equal true, @rubyforge.userconfig['preformatted']
        end
        
        should "add release" do
          assert_received(@rubyforge) {|rubyforge| rubyforge.add_release("MyRubyForgeProjectName", "zomg", "1.2.3", "pkg/zomg-1.2.3.gem") }
        end
      end

      rubyforge_command_context "rubyforge_project is defined in gemspec and package does not exist on rubyforge" do
        setup do
          stub(@rubyforge).configure
          stub(@rubyforge).login
          stub(@rubyforge).scrape_config
          stub(@rubyforge).add_release("MyRubyForgeProjectName", "zomg", "1.2.3", "pkg/zomg-1.2.3.gem") {
            raise "no <package_id> configured for <zomg>"
          }

          stub(@gemspec).description {"The zomg gem rocks."}
          stub(@gemspec).rubyforge_project {"MyRubyForgeProjectName"}
          stub(@gemspec).name {"zomg"}
          
          stub(@gemspec_helper).write
          stub(@gemspec_helper).gem_path {'pkg/zomg-1.2.3.gem'}
          stub(@gemspec_helper).update_version('1.2.3')

          @command.version        = '1.2.3'
        end

        should "raise MissingRubyForgePackageError" do
          assert_raises Jeweler::MissingRubyForgePackageError do
            @command.run
          end
        end
      end
      
      rubyforge_command_context "rubyforge_project is not defined in gemspec" do
        setup do
          stub(@rubyforge).configure
          stub(@rubyforge).login
          stub(@rubyforge).add_release(nil, "zomg", "1.2.3", "pkg/zomg-1.2.3.gem")

          stub(@gemspec).description {"The zomg gem rocks."}
          stub(@gemspec).rubyforge_project { nil }
          stub(@gemspec).name {"zomg"}
          
          stub(@gemspec_helper).write
          stub(@gemspec_helper).gem_path {'pkg/zomg-1.2.3.gem'}
          stub(@gemspec_helper).update_version('1.2.3')

          @command.version        = '1.2.3'
        end
        
        should "raise NoRubyForgeProjectConfigured" do
          assert_raises Jeweler::NoRubyForgeProjectInGemspecError do
            @command.run
          end
        end
      end
      
      rubyforge_command_context "after running when rubyforge_project is not defined in ~/.rubyforge/auto_config.yml" do
        setup do
          stub(@rubyforge).configure
          stub(@rubyforge).login
          stub(@rubyforge).add_release("some_project_that_doesnt_exist", "zomg", "1.2.3", "pkg/zomg-1.2.3.gem") do
            raise RuntimeError, "no <group_id> configured for <some_project_that_doesnt_exist>"
          end

          @rubyforge.autoconfig['package_ids'] = { 'zomg' => 1234 }

          stub(@gemspec).description {"The zomg gem rocks."}
          stub(@gemspec).rubyforge_project { "some_project_that_doesnt_exist" }
          stub(@gemspec).name {"zomg"}
          
          stub(@gemspec_helper).write
          stub(@gemspec_helper).gem_path {'pkg/zomg-1.2.3.gem'}
          stub(@gemspec_helper).update_version('1.2.3')

          @command.version        = '1.2.3'
        end
        
        should "raise error" do
          assert_raises RuntimeError, /no <group_id> configured/i do
            @command.run
          end
        end
      end
      
    end
  end
end
