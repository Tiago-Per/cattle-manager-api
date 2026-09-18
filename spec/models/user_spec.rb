require "rails_helper"

RSpec.describe User, type: :model do
  it "allows a blank phone number" do
    user = build(:user, phone_number: nil)

    expect(user).to be_valid
  end

  it "rejects a phone number that isn't in international format" do
    user = build(:user, phone_number: "call me maybe")

    expect(user).not_to be_valid
    expect(user.errors).to have_key(:phone_number)
  end
end
