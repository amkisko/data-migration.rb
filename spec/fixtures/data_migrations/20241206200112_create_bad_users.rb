class CreateGoodUsers
  def perform(**kwargs)
    User.find_or_create_by(email: "test@example.com")
  end
end
