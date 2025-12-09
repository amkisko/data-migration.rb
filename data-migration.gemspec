Gem::Specification.new do |gem|
  gem.name = "data-migration"
  gem.version = File.read(File.expand_path("../lib/data-migration.rb", __FILE__)).match(/VERSION\s*=\s*"(.*?)"/)[1]

  root_files = %w[CHANGELOG.md LICENSE.md README.md]
  root_files << "#{gem.name}.gemspec"

  gem.license = "MIT"

  gem.platform = Gem::Platform::RUBY

  gem.authors = ["Andrei Makarov"]
  gem.email = ["contact@kiskolabs.com"]
  gem.homepage = "https://github.com/amkisko/data-migration.rb"
  gem.summary = "Data migrations kit for ActiveRecord and ActiveJob"
  gem.description = gem.summary
  gem.metadata = {
    "homepage" => "https://github.com/amkisko/data-migration.rb",
    "source_code_uri" => "https://github.com/amkisko/data-migration.rb",
    "bug_tracker_uri" => "https://github.com/amkisko/data-migration.rb/issues",
    "changelog_uri" => "https://github.com/amkisko/data-migration.rb/blob/main/CHANGELOG.md",
    "rubygems_mfa_required" => "true"
  }

  gem.files = `git ls-files`.split("\n")
  gem.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }

  gem.required_ruby_version = ">= 3"
  gem.require_paths = ["lib"]

  gem.add_dependency "rails", "> 5"
  gem.add_dependency "activejob", "> 5"
  gem.add_dependency "activerecord", "> 5"
  gem.add_dependency "activesupport", "> 5"

  gem.add_development_dependency "bundler", "~> 2"
  gem.add_development_dependency "rspec", "~> 3"
  gem.add_development_dependency "webmock", "~> 3"
  gem.add_development_dependency "rspec_junit_formatter", "~> 0.6"
  gem.add_development_dependency "simplecov", "~> 0.22"
  gem.add_development_dependency "simplecov-cobertura", "~> 3"
  gem.add_development_dependency "rbs", "~> 3"
  gem.add_development_dependency "standard", "~> 1.52"
  gem.add_development_dependency "standard-custom", "~> 1.0"
  gem.add_development_dependency "standard-performance", "~> 1.8"
  gem.add_development_dependency "standard-rails", "~> 1.5"
  gem.add_development_dependency "standard-rspec", "~> 0.3"
  gem.add_development_dependency "rubocop-rails", "~> 2.33"
  gem.add_development_dependency "rubocop-rspec", "~> 3.8"
  gem.add_development_dependency "rubocop-thread_safety", "~> 0.7"
  gem.add_development_dependency "appraisal", "~> 2"
end
