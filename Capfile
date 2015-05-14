# Load DSL and set up stages
require "capistrano/setup"

# Include default deployment tasks
require "capistrano/deploy"
require "capistrano/bundler"
require "capistrano/rvm"
require "capistrano/npm"

Dir.glob("lib/capistrano/tasks/*.rake").each { |r| import r }
