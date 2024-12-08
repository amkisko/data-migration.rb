class CreateUsers
  def perform(**kwargs)
    User.find_or_create_by(email: "test@example.com")
  end
end

if Object.const_defined?(:RSpec)
  require "spec_helper"

  RSpec.describe CreateUsers, type: :data_migration do
    subject(:perform) { described_class.new.perform }

    it do
      expect { perform }.not_to raise_error
    end
  end
end
