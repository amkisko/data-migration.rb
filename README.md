# data-migration.rb

[![Gem Version](https://badge.fury.io/rb/data-migration.svg)](https://badge.fury.io/rb/data-migration) [![Test Status](https://github.com/amkisko/data-migration.rb/actions/workflows/test.yml/badge.svg)](https://github.com/amkisko/data-migration.rb/actions/workflows/test.yml) [![codecov](https://codecov.io/gh/amkisko/data-migration.rb/graph/badge.svg?token=881AFPL643)](https://codecov.io/gh/amkisko/data-migration.rb)

Data migrations kit for ActiveRecord and ActiveJob.

Sponsored by [Kisko Labs](https://www.kiskolabs.com).

<a href="https://www.kiskolabs.com">
  <img src="https://brand.kiskolabs.com/images/logos/Kisko_Logo_Black_Horizontal-7249a361.svg" width="200" style="display: block; background: white; border-radius: 10px;" />
</a>


## Data migrations concept

- A short-living script that is manually applied to database
- Not reversible
- Can be applied multiple times
- Accompanied by ActiveJob for background and batch operations
- Accompanied by ActiveRecord to control and audit migrations progress
- Operator's responsibility to ensure data consistency, notifications, monitoring and quality of implementation

### Data migrations process

1. Avoid implementing and running data migrations within schema migrations
2. Data migrations should be planned beforehand, reserve time in the calendar
3. Data migrations should be always controlled by operator
4. Wrapping queries to transactions might lead to large memory consumption, unexpected exceptions and database unresponsiveness
5. Large data migrations should have batching implemented which will lower memory consumption and database load
6. Critical data migrations should be covered with tests, by finding consensus developers decide if migration is critical
7. Before running critical data migrations, make sure that you have fresh backup of the database and you are ready to rollback in case of failure

## Installation

Using Bundler:

```sh
bundle add data-migration
```

Using RubyGems:

```sh
gem install data-migration
```

### Gemfile

```ruby
gem "data-migration"
```

### Data migration tasks table

```sh
bin/rails g data_migration:install data_migration_tasks
```

## Usage

### Generate data migration job

```sh
bin/rails g data_migration create_users
```

### Run data migrations

```sh
bin/rails db:migrate:data 20241207120000_create_users
```

## Configuration

### Set data migrations directory

Absolute path will be resolved by using `Rails.root`.

```ruby
DataMigration.config.data_migrations_path = "db/data_migrations"
```

### Turn off test script generation

```ruby
DataMigration.config.generate_spec = false
```

## Batch operations

Batch operations are supported by using `enqueue` method, it will automatically enqueue or perform next job depending on `background` option.

`enqueue` method calls are tracked within a single Thread, it should be used within a single job execution, also all `enqueue` calls rewrite each other and only last call will be used for enqueuing next job after the current job is completed.

```ruby
def perform(index: 1, background: true)
  return if index > 2

  User.find_or_create_by(email: "test_#{index}@example.com")

  enqueue(index: index + 1, background:)
end
```

## Specification checklist

- [x] User can generate data migration file under `db/data_migrations` directory with common format
- [x] User can generate data migration file with test script included
- [x] User can run specific data migration using Rails console
- [ ] User can run specific data migration using shell command
- [x] User can run data migration in background
- [x] User can run data migration in foreground
- [x] User can specify operator for data migration
- [x] User can specify monitoring context for data migration
- [x] User can specify pause time for data migration
- [x] User can specify jobs limit for data migration
- [ ] User receives an error when data migration is applied within schema migration

## Limitations & explanations

- ActiveRecord migrations generator is used to generate data migration files
- Data migrations are not reversible, it is operator's responsibility to ensure that data migration has correct effect
- Keep migrations logic stable and predictable, e.g. by checking uniqueness of created/updated records

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/amkisko/data-migration.rb>

Contribution policy:

- New features are not necessarily added to the gem
- Pull request should have test coverage for affected parts
- Pull request should have changelog entry
- It might take up to 2 calendar weeks to review and merge critical fixes
- It might take up to 6 calendar months to review and merge pull request
- It might take up to 1 calendar year to review an issue

## Publishing

Prefer using script `usr/bin/release.sh`, it will ensure that repository is synced and after publishing gem will create a tag.

```sh
GEM_VERSION=$(grep -Eo "VERSION\s*=\s*\".+\"" lib/data-migration.rb  | grep -Eo "[0-9.]{5,}")
rm data-migration-*.gem
gem build data-migration.gemspec
gem push data-migration-$GEM_VERSION.gem
git tag $GEM_VERSION && git push --tags && gh release create $GEM_VERSION --generate-notes
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
