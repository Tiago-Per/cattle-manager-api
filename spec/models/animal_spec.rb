require "rails_helper"

RSpec.describe Animal, type: :model do
  describe "category/sex validation" do
    it "rejects category 'cow' for a male animal" do
      animal = build(:animal, category: "cow", sex: "male")

      expect(animal).not_to be_valid
      expect(animal.errors[:category]).to be_present
    end

    it "rejects category 'heifer' for a male animal" do
      animal = build(:animal, category: "heifer", sex: "male")

      expect(animal).not_to be_valid
    end

    it "rejects category 'bull' for a female animal" do
      animal = build(:animal, category: "bull", sex: "female")

      expect(animal).not_to be_valid
      expect(animal.errors[:category]).to be_present
    end

    it "rejects category 'steer' for a female animal" do
      animal = build(:animal, category: "steer", sex: "female")

      expect(animal).not_to be_valid
    end

    it "accepts a matching category and sex" do
      animal = build(:animal, category: "cow", sex: "female")

      expect(animal).to be_valid
    end
  end

  describe "identification uniqueness" do
    it "rejects a duplicate identification" do
      create(:animal, identification: "TAG-1")
      duplicate = build(:animal, identification: "TAG-1")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:identification]).to be_present
    end
  end

  describe "birth_date validation" do
    it "rejects a future birth date" do
      animal = build(:animal, birth_date: 1.day.from_now.to_date)

      expect(animal).not_to be_valid
      expect(animal.errors[:birth_date]).to be_present
    end

    it "accepts a missing birth date" do
      animal = build(:animal, birth_date: nil)

      expect(animal).to be_valid
    end
  end
end
