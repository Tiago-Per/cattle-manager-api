module AuthenticationHelpers
  def auth_headers(user)
    Devise::JWT::TestHelpers.auth_headers({}, user)
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
end
