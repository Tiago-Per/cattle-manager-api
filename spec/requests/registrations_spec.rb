require "rails_helper"

RSpec.describe "Api::V1::Registrations", type: :request do
  describe "POST /api/v1/signup" do
    it "creates a user" do
      params = { user: { email: "producer@example.com", password: "password123" } }

      post "/api/v1/signup", params: params

      expect(response).to have_http_status(:created)
      expect(User.exists?(email: "producer@example.com")).to be true
    end

    it "returns 422 when the email is already taken" do
      create(:user, email: "producer@example.com")
      params = { user: { email: "producer@example.com", password: "password123" } }

      post "/api/v1/signup", params: params

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to have_key("email")
    end
  end
end
