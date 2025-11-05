Gem::Specification.new do |gem|
  gem.name = "data-migration"
  gem.version = File.read(File.expand_path("../lib/data-migration.rb", __FILE__)).match(/VERSION\s*=\s*"(.*?)"/)[1]

  repository_url = "https://github.com/amkisko/data-migration.rb"
  root_files = %w[CHANGELOG.md LICENSE.md README.md]
  root_files << "#{gem.name}.gemspec"

  gem.license = "MIT"

  gem.platform = Gem::Platform::RUBY

  gem.authors = ["Andrei Makarov"]
  gem.email = ["contact@kiskolabs.com"]
  gem.homepage = repository_url
  gem.summary = "Data migrations kit for ActiveRecord and ActiveJob"
  gem.description = gem.summary
  gem.metadata = {
    "homepage" => repository_url,
    "source_code_uri" => repository_url,
    "bug_tracker_uri" => "#{repository_url}/issues",
    "changelog_uri" => "#{repository_url}/blob/main/CHANGELOG.md",
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
  gem.add_development_dependency "simplecov", "~> 0.21"
  gem.add_development_dependency "simplecov-cobertura", "~> 2"
  gem.add_development_dependency "sqlite3", "~> 2.4"
end
