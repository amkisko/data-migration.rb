class CreateBatchUsers
  def perform(index: 1, background: false)
    return if index > 2

    User.find_or_create_by(email: "test_#{index}@example.com")

    enqueue(index: index + 1, background:)
  end
end
