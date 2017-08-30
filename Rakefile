desc 'List all rake tasks (rake -T)'
task(:default) do
  Rake.application.options.show_tasks = :tasks
  Rake.application.options.show_task_pattern = //
  Rake.application.display_tasks_and_comments
end

Rake::TaskManager.record_task_metadata = true

require 'bundler/gem_tasks'
# require 'rake/testtask'

include Rake::DSL

desc 'Start Swarm'
task(:start) { exec File.join(__dir__, 'bin/swarm') }

desc 'Build Swarm Documentation'
task(:doc) { exec 'yard; ruby -run -ehttpd doc -p8080' }

# Rake::TestTask.new do |t|
#   t.libs << 'test'
#   t.test_files = FileList['test/*_test.rb']
#   t.verbose = true
# end

