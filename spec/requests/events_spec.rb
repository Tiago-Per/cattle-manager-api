require "rails_helper"

RSpec.describe "Api::V1::Events", type: :request do
  describe "GET /api/v1/animals/:animal_id/events" do
    it "returns the animal's events ordered by occurred_on descending" do
      animal = create(:animal)
      older = create(:event, :vaccination, animal: animal, occurred_on: 10.days.ago.to_date)
      newer = create(:event, :vaccination, animal: animal, occurred_on: 1.day.ago.to_date)

      get "/api/v1/animals/#{animal.id}/events"

      expect(response).to have_http_status(:ok)
      ids = JSON.parse(response.body).map { |event| event["id"] }
      expect(ids).to eq([ newer.id, older.id ])
    end

    it "returns 404 when the animal does not exist" do
      get "/api/v1/animals/0/events"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/animals/:animal_id/events" do
    it "creates an event for the animal" do
      animal = create(:animal)
      params = { event: { event_type: "weight", occurred_on: Date.current, weight_kg: 210.5 } }

      post "/api/v1/animals/#{animal.id}/events", params: params

      expect(response).to have_http_status(:created)
      expect(animal.events.count).to eq(1)
    end

    it "returns 422 when the event is invalid" do
      animal = create(:animal)
      params = { event: { event_type: "weight", occurred_on: Date.current } }

      post "/api/v1/animals/#{animal.id}/events", params: params

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to have_key("weight_kg")
    end
  end

  describe "GET /api/v1/events/:id" do
    it "returns the event" do
      event = create(:event, :weight, animal: create(:animal))

      get "/api/v1/events/#{event.id}"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["id"]).to eq(event.id)
    end

    it "returns 404 when the event does not exist" do
      get "/api/v1/events/0"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/v1/events/:id" do
    it "updates the event" do
      event = create(:event, :weight, animal: create(:animal), weight_kg: 200)

      patch "/api/v1/events/#{event.id}", params: { event: { weight_kg: 220 } }

      expect(response).to have_http_status(:ok)
      expect(event.reload.weight_kg).to eq(220)
    end

    it "returns 422 when the update is invalid" do
      event = create(:event, :weight, animal: create(:animal))

      patch "/api/v1/events/#{event.id}", params: { event: { weight_kg: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to have_key("weight_kg")
    end
  end

  describe "DELETE /api/v1/events/:id" do
    it "deletes the event" do
      event = create(:event, :weight, animal: create(:animal))

      delete "/api/v1/events/#{event.id}"

      expect(response).to have_http_status(:no_content)
      expect(Event.exists?(event.id)).to be false
    end

    it "returns 404 when the event does not exist" do
      delete "/api/v1/events/0"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "estimates in the JSON response" do
    it "includes the estimates object for a breeding event" do
      event = create(:event, :breeding, animal: create(:animal))

      get "/api/v1/events/#{event.id}"

      estimates = JSON.parse(response.body)["estimates"]
      expect(estimates).to include(
        "expected_calving_date" => event.expected_calving_date.to_s,
        "expected_estrus_date" => event.expected_estrus_date.to_s,
        "disclaimer" => "Estimated from average bovine values. Not a veterinary prediction."
      )
    end

    it "omits the estimates key for a weight event" do
      event = create(:event, :weight, animal: create(:animal))

      get "/api/v1/events/#{event.id}"

      expect(JSON.parse(response.body)).not_to have_key("estimates")
    end
  end
end
