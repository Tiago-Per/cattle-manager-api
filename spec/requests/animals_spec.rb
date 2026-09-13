require "rails_helper"

RSpec.describe "Api::V1::Animals", type: :request do
  let(:user) { create(:user) }

  describe "GET /api/v1/animals" do
    it "returns the current user's animals" do
      create_list(:animal, 2, user: user)
      create(:animal)

      get "/api/v1/animals", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).size).to eq(2)
    end

    it "returns 401 when the request is not authenticated" do
      get "/api/v1/animals"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/animals/:id" do
    it "returns the animal" do
      animal = create(:animal, user: user)

      get "/api/v1/animals/#{animal.id}", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["identification"]).to eq(animal.identification)
    end

    it "returns 404 when the animal does not exist" do
      get "/api/v1/animals/0", headers: auth_headers(user)

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 when the animal belongs to another user" do
      other_animal = create(:animal)

      get "/api/v1/animals/#{other_animal.id}", headers: auth_headers(user)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/animals" do
    it "creates an animal owned by the current user" do
      params = { animal: { identification: "TAG-1", category: "cow", sex: "female", status: "active" } }

      post "/api/v1/animals", params: params, headers: auth_headers(user)

      expect(response).to have_http_status(:created)
      expect(user.animals.count).to eq(1)
    end

    it "returns 422 when the category doesn't match the sex" do
      params = { animal: { identification: "TAG-1", category: "cow", sex: "male", status: "active" } }

      post "/api/v1/animals", params: params, headers: auth_headers(user)

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to have_key("category")
    end
  end

  describe "PATCH /api/v1/animals/:id" do
    it "updates the animal" do
      animal = create(:animal, user: user, status: "active")

      patch "/api/v1/animals/#{animal.id}", params: { animal: { status: "sold" } }, headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(animal.reload.status).to eq("sold")
    end

    it "returns 422 when the update is invalid" do
      animal = create(:animal, user: user)

      patch "/api/v1/animals/#{animal.id}", params: { animal: { identification: "" } }, headers: auth_headers(user)

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to have_key("identification")
    end

    it "returns 404 when the animal belongs to another user" do
      other_animal = create(:animal)

      patch "/api/v1/animals/#{other_animal.id}", params: { animal: { status: "sold" } }, headers: auth_headers(user)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/v1/animals/:id" do
    it "deletes the animal" do
      animal = create(:animal, user: user)

      delete "/api/v1/animals/#{animal.id}", headers: auth_headers(user)

      expect(response).to have_http_status(:no_content)
      expect(Animal.exists?(animal.id)).to be false
    end

    it "returns 404 when the animal does not exist" do
      delete "/api/v1/animals/0", headers: auth_headers(user)

      expect(response).to have_http_status(:not_found)
    end

    it "returns 422 when the animal has events" do
      animal = create(:animal, user: user)
      create(:event, :vaccination, animal: animal)

      delete "/api/v1/animals/#{animal.id}", headers: auth_headers(user)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 404 when the animal belongs to another user" do
      other_animal = create(:animal)

      delete "/api/v1/animals/#{other_animal.id}", headers: auth_headers(user)

      expect(response).to have_http_status(:not_found)
      expect(Animal.exists?(other_animal.id)).to be true
    end
  end
end
