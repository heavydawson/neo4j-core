require 'rake'
require 'rcov/rcovtask'
require "bundler/gem_tasks"

FileList = Rake::FileList

Rcov::RcovTask.new do |t|
  t.libs << "spec"
  t.test_files = Rake::FileList['spec/**/*_spec.rb']
  t.verbose = true
end