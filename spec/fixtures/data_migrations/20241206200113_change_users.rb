class ChangeUsers
  def change(**kwargs)
    User.find_or_create_by(email: "test@example.com")
  end
end
