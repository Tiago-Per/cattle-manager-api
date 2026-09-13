require "rails_helper"

RSpec.describe Event, type: :model do
  describe "weight_kg validation" do
    it "requires weight_kg for a weight event" do
      event = build(:event, :weight, weight_kg: nil)

      expect(event).not_to be_valid
      expect(event.errors[:weight_kg]).to be_present
    end

    it "rejects weight_kg for a vaccination event" do
      event = build(:event, :vaccination, weight_kg: 200)

      expect(event).not_to be_valid
      expect(event.errors[:weight_kg]).to be_present
    end

    it "rejects weight_kg for a breeding event" do
      event = build(:event, :breeding, weight_kg: 200)

      expect(event).not_to be_valid
      expect(event.errors[:weight_kg]).to be_present
    end

    it "accepts a weight event with weight_kg present" do
      event = build(:event, :weight)

      expect(event).to be_valid
    end
  end

  describe "product_name validation" do
    it "requires product_name for a vaccination event" do
      event = build(:event, :vaccination, product_name: nil)

      expect(event).not_to be_valid
      expect(event.errors[:product_name]).to be_present
    end

    it "rejects product_name for a weight event" do
      event = build(:event, :weight, product_name: "Aftosa")

      expect(event).not_to be_valid
      expect(event.errors[:product_name]).to be_present
    end

    it "rejects product_name for a breeding event" do
      event = build(:event, :breeding, product_name: "Aftosa")

      expect(event).not_to be_valid
      expect(event.errors[:product_name]).to be_present
    end

    it "accepts a vaccination event with product_name present" do
      event = build(:event, :vaccination)

      expect(event).to be_valid
    end
  end

  describe "sire_identification validation" do
    it "requires sire_identification for a breeding event" do
      event = build(:event, :breeding, sire_identification: nil)

      expect(event).not_to be_valid
      expect(event.errors[:sire_identification]).to be_present
    end

    it "rejects sire_identification for a weight event" do
      event = build(:event, :weight, sire_identification: "TAG-SIRE-1")

      expect(event).not_to be_valid
      expect(event.errors[:sire_identification]).to be_present
    end

    it "rejects sire_identification for a vaccination event" do
      event = build(:event, :vaccination, sire_identification: "TAG-SIRE-1")

      expect(event).not_to be_valid
      expect(event.errors[:sire_identification]).to be_present
    end

    it "accepts a breeding event with sire_identification present" do
      event = build(:event, :breeding)

      expect(event).to be_valid
    end
  end

  describe "due_on validation" do
    it "rejects due_on for a weight event" do
      event = build(:event, :weight, due_on: 1.month.from_now.to_date)

      expect(event).not_to be_valid
      expect(event.errors[:due_on]).to be_present
    end

    it "rejects due_on for a breeding event" do
      event = build(:event, :breeding, due_on: 1.month.from_now.to_date)

      expect(event).not_to be_valid
      expect(event.errors[:due_on]).to be_present
    end

    it "accepts due_on for a vaccination event" do
      event = build(:event, :vaccination, due_on: 1.month.from_now.to_date)

      expect(event).to be_valid
    end
  end

  describe "occurred_on validation" do
    it "rejects a future occurred_on" do
      event = build(:event, :weight, occurred_on: 1.day.from_now.to_date)

      expect(event).not_to be_valid
      expect(event.errors[:occurred_on]).to be_present
    end

    it "accepts today as occurred_on" do
      event = build(:event, :weight, occurred_on: Date.current)

      expect(event).to be_valid
    end
  end

  describe "#expected_calving_date" do
    it "is 283 days after occurred_on for a breeding event" do
      event = build(:event, :breeding, occurred_on: Date.new(2026, 1, 1))

      expect(event.expected_calving_date).to eq(Date.new(2026, 1, 1) + 283.days)
    end

    it "is nil for a non-breeding event" do
      event = build(:event, :weight)

      expect(event.expected_calving_date).to be_nil
    end
  end

  describe "#expected_estrus_date" do
    it "is 21 days after occurred_on for a breeding event" do
      event = build(:event, :breeding, occurred_on: Date.new(2026, 1, 1))

      expect(event.expected_estrus_date).to eq(Date.new(2026, 1, 1) + 21.days)
    end

    it "is nil for a non-breeding event" do
      event = build(:event, :weight)

      expect(event.expected_estrus_date).to be_nil
    end
  end

  describe ".calving_due_between" do
    it "returns breeding events whose expected calving date falls in the range" do
      due_soon = create(:event, :breeding, occurred_on: Date.current - 280.days)
      due_later = create(:event, :breeding, occurred_on: Date.current - 100.days)

      result = Event.calving_due_between(Date.current, 5.days.from_now.to_date)

      expect(result).to include(due_soon)
      expect(result).not_to include(due_later)
    end

    it "excludes non-breeding events" do
      create(:event, :weight, occurred_on: Date.current - 280.days)

      result = Event.calving_due_between(Date.current, 5.days.from_now.to_date)

      expect(result).to be_empty
    end
  end

  describe ".estrus_due_between" do
    it "returns breeding events whose expected estrus date falls in the range" do
      due_soon = create(:event, :breeding, occurred_on: Date.current - 20.days)
      due_later = create(:event, :breeding, occurred_on: Date.current - 5.days)

      result = Event.estrus_due_between(Date.current, 5.days.from_now.to_date)

      expect(result).to include(due_soon)
      expect(result).not_to include(due_later)
    end

    it "excludes non-breeding events" do
      create(:event, :weight, occurred_on: Date.current - 20.days)

      result = Event.estrus_due_between(Date.current, 5.days.from_now.to_date)

      expect(result).to be_empty
    end
  end
end
