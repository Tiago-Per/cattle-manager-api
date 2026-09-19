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

  describe "pregnancy check" do
    it "defaults a breeding event to pending" do
      event = create(:event, :breeding)

      expect(event.pregnancy_check_result).to eq("pending")
    end

    it "rejects a pregnancy check result for a weight event" do
      event = build(:event, :weight, pregnancy_check_result: "confirmed", pregnancy_checked_on: Date.current)

      expect(event).not_to be_valid
      expect(event.errors[:pregnancy_check_result]).to be_present
    end

    it "rejects a pregnancy check date for a vaccination event" do
      event = build(:event, :vaccination, pregnancy_checked_on: Date.current)

      expect(event).not_to be_valid
      expect(event.errors[:pregnancy_checked_on]).to be_present
    end

    it "requires the check date when the result is confirmed" do
      event = build(:event, :breeding, pregnancy_check_result: "confirmed", pregnancy_checked_on: nil)

      expect(event).not_to be_valid
      expect(event.errors[:pregnancy_checked_on]).to be_present
    end

    it "requires the check date when the result is negative" do
      event = build(:event, :breeding, pregnancy_check_result: "negative", pregnancy_checked_on: nil)

      expect(event).not_to be_valid
      expect(event.errors[:pregnancy_checked_on]).to be_present
    end

    it "does not require the check date while the result is pending" do
      event = build(:event, :breeding, pregnancy_check_result: "pending", pregnancy_checked_on: nil)

      expect(event).to be_valid
    end

    it "rejects a check date while the result is pending" do
      event = build(:event, :breeding, pregnancy_check_result: "pending", pregnancy_checked_on: Date.current)

      expect(event).not_to be_valid
      expect(event.errors[:pregnancy_checked_on]).to be_present
    end

    it "rejects a check date in the future" do
      event = build(:event, :breeding, pregnancy_check_result: "confirmed",
                                       pregnancy_checked_on: 1.day.from_now.to_date)

      expect(event).not_to be_valid
      expect(event.errors[:pregnancy_checked_on]).to be_present
    end

    it "rejects a check date before the breeding date" do
      event = build(:event, :breeding, occurred_on: Date.current - 10.days,
                                       pregnancy_check_result: "confirmed",
                                       pregnancy_checked_on: Date.current - 11.days)

      expect(event).not_to be_valid
      expect(event.errors[:pregnancy_checked_on]).to be_present
    end

    it "accepts a check date on the breeding date" do
      event = build(:event, :breeding, occurred_on: Date.current - 10.days,
                                       pregnancy_check_result: "negative",
                                       pregnancy_checked_on: Date.current - 10.days)

      expect(event).to be_valid
    end
  end

  describe "#expected_calving_date" do
    let(:occurred_on) { Date.new(2026, 1, 1) }

    it "is 283 days after occurred_on when the result is confirmed" do
      event = build(:event, :breeding, occurred_on: occurred_on, pregnancy_check_result: "confirmed",
                                       pregnancy_checked_on: occurred_on + 30.days)

      expect(event.expected_calving_date).to eq(occurred_on + 283.days)
    end

    it "is nil when the result is pending" do
      event = build(:event, :breeding, occurred_on: occurred_on, pregnancy_check_result: "pending")

      expect(event.expected_calving_date).to be_nil
    end

    it "is nil when the result is negative" do
      event = build(:event, :breeding, occurred_on: occurred_on, pregnancy_check_result: "negative",
                                       pregnancy_checked_on: occurred_on + 30.days)

      expect(event.expected_calving_date).to be_nil
    end

    it "is nil for a non-breeding event" do
      event = build(:event, :weight)

      expect(event.expected_calving_date).to be_nil
    end
  end

  describe "#expected_estrus_date" do
    let(:occurred_on) { Date.new(2026, 1, 1) }

    it "is 21 days after occurred_on when the result is pending" do
      event = build(:event, :breeding, occurred_on: occurred_on, pregnancy_check_result: "pending")

      expect(event.expected_estrus_date).to eq(occurred_on + 21.days)
    end

    it "is 21 days after occurred_on when the result is negative" do
      event = build(:event, :breeding, occurred_on: occurred_on, pregnancy_check_result: "negative",
                                       pregnancy_checked_on: occurred_on + 30.days)

      expect(event.expected_estrus_date).to eq(occurred_on + 21.days)
    end

    it "is nil when the result is confirmed" do
      event = build(:event, :breeding, occurred_on: occurred_on, pregnancy_check_result: "confirmed",
                                       pregnancy_checked_on: occurred_on + 30.days)

      expect(event.expected_estrus_date).to be_nil
    end

    it "is nil for a non-breeding event" do
      event = build(:event, :weight)

      expect(event.expected_estrus_date).to be_nil
    end
  end

  describe ".calving_due_between" do
    let(:range) { [ Date.current, 5.days.from_now.to_date ] }

    it "returns confirmed breeding events whose expected calving date falls in the range" do
      due_soon = create(:event, :breeding, occurred_on: Date.current - 280.days,
                                           pregnancy_check_result: "confirmed",
                                           pregnancy_checked_on: Date.current - 200.days)
      due_later = create(:event, :breeding, occurred_on: Date.current - 100.days,
                                            pregnancy_check_result: "confirmed",
                                            pregnancy_checked_on: Date.current - 50.days)

      result = Event.calving_due_between(*range)

      expect(result).to include(due_soon)
      expect(result).not_to include(due_later)
    end

    it "excludes a pending result" do
      create(:event, :breeding, occurred_on: Date.current - 280.days, pregnancy_check_result: "pending")

      expect(Event.calving_due_between(*range)).to be_empty
    end

    it "excludes a negative result" do
      create(:event, :breeding, occurred_on: Date.current - 280.days,
                                pregnancy_check_result: "negative",
                                pregnancy_checked_on: Date.current - 200.days)

      expect(Event.calving_due_between(*range)).to be_empty
    end

    it "excludes non-breeding events" do
      create(:event, :weight, occurred_on: Date.current - 280.days)

      expect(Event.calving_due_between(*range)).to be_empty
    end
  end

  describe ".estrus_due_between" do
    let(:range) { [ Date.current, 5.days.from_now.to_date ] }

    it "returns breeding events whose expected estrus date falls in the range" do
      due_soon = create(:event, :breeding, occurred_on: Date.current - 20.days)
      due_later = create(:event, :breeding, occurred_on: Date.current - 5.days)

      result = Event.estrus_due_between(*range)

      expect(result).to include(due_soon)
      expect(result).not_to include(due_later)
    end

    it "includes a pending result" do
      event = create(:event, :breeding, occurred_on: Date.current - 20.days, pregnancy_check_result: "pending")

      expect(Event.estrus_due_between(*range)).to include(event)
    end

    it "includes a negative result" do
      event = create(:event, :breeding, occurred_on: Date.current - 20.days,
                                        pregnancy_check_result: "negative",
                                        pregnancy_checked_on: Date.current - 10.days)

      expect(Event.estrus_due_between(*range)).to include(event)
    end

    it "excludes a confirmed result" do
      create(:event, :breeding, occurred_on: Date.current - 20.days,
                                pregnancy_check_result: "confirmed",
                                pregnancy_checked_on: Date.current - 10.days)

      expect(Event.estrus_due_between(*range)).to be_empty
    end

    it "excludes non-breeding events" do
      create(:event, :weight, occurred_on: Date.current - 20.days)

      expect(Event.estrus_due_between(*range)).to be_empty
    end
  end
end
