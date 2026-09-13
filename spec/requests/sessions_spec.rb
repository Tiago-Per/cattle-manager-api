require "rails_helper"

RSpec.describe "Api::V1::Sessions", type: :request do
  describe "POST /api/v1/login" do
    it "returns a JWT in the Authorization header" do
      user = create(:user, password: "password123")

      post "/api/v1/login", params: { user: { email: user.email, password: "password123" } }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Authorization"]).to match(/^Bearer /)
    end

    it "returns 401 when the credentials are invalid" do
      user = create(:user, password: "password123")

      post "/api/v1/login", params: { user: { email: user.email, password: "wrong" } }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/logout" do
    it "revokes the current token" do
      user = create(:user, password: "password123")
      headers = auth_headers(user)

      delete "/api/v1/logout", headers: headers

      expect(response).to have_http_status(:no_content)

      get "/api/v1/animals", headers: headers
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 when the request is not authenticated" do
      delete "/api/v1/logout"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
