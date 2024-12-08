module RailsHelpers
  class User < ActiveRecord::Base
    self.table_name = "users"
  end

  def rails_root(destination_root = File.expand_path("../../tmp/rspec", __dir__))
    Class.new do
      def initialize(destination_root)
        @destination_root = destination_root
      end

      def to_s
        @destination_root
      end

      def join(*args)
        File.join(@destination_root, *args)
      end
    end.new(destination_root)
  end

  def rails_env(env = "development")
    Class.new do
      def initialize(env)
        @env = env.to_s
      end

      def development?
        @env == "development"
      end

      def test?
        @env == "test"
      end

      def production?
        @env == "production"
      end

      def to_s
        @env
      end
    end.new(env)
  end

  def rails_logger
    Class.new do
      def info(message)
        puts message
      end
    end.new
  end
end
