class FailUsers
  def perform(fail: true)
    return unless fail

    enqueue(index: 2)
    raise "migration failed"
  end
end
