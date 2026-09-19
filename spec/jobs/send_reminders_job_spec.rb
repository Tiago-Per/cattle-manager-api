require "rails_helper"

RSpec.describe SendRemindersJob, type: :job do
  let(:window_start) { Date.current }
  let(:window_end) { 7.days.from_now.to_date }

  before do
    allow(Notifications::Dispatcher).to receive(:deliver)
  end

  it "sends a reminder for an opted-in user with upcoming items" do
    user = create(:user, :whatsapp_subscriber)
    animal = create(:animal, user: user, identification: "TAG-1")
    create(:event, :vaccination, animal: animal, due_on: 3.days.from_now.to_date)

    described_class.perform_now(window_start, window_end)

    expect(Notifications::Dispatcher).to have_received(:deliver).once.with(
      to: user.phone_number,
      body: a_string_including("TAG-1")
    )
  end

  it "skips a user who has not opted in" do
    user = create(:user, whatsapp_opt_in: false, phone_number: "+15550001111")
    animal = create(:animal, user: user)
    create(:event, :vaccination, animal: animal, due_on: 3.days.from_now.to_date)

    described_class.perform_now(window_start, window_end)

    expect(Notifications::Dispatcher).not_to have_received(:deliver)
  end

  it "skips an opted-in user without a phone number" do
    user = create(:user, whatsapp_opt_in: true, phone_number: nil)
    animal = create(:animal, user: user)
    create(:event, :vaccination, animal: animal, due_on: 3.days.from_now.to_date)

    described_class.perform_now(window_start, window_end)

    expect(Notifications::Dispatcher).not_to have_received(:deliver)
  end

  it "skips a user with nothing upcoming in the window" do
    user = create(:user, :whatsapp_subscriber)
    animal = create(:animal, user: user)
    create(:event, :vaccination, animal: animal, due_on: 30.days.from_now.to_date)

    described_class.perform_now(window_start, window_end)

    expect(Notifications::Dispatcher).not_to have_received(:deliver)
  end

  it "never mixes one user's items into another user's message" do
    user_a = create(:user, :whatsapp_subscriber)
    animal_a = create(:animal, user: user_a, identification: "TAG-1")
    create(:event, :vaccination, animal: animal_a, due_on: 3.days.from_now.to_date)

    user_b = create(:user, :whatsapp_subscriber)
    animal_b = create(:animal, user: user_b, identification: "TAG-2")
    create(:event, :vaccination, animal: animal_b, due_on: 4.days.from_now.to_date)

    described_class.perform_now(window_start, window_end)

    expect(Notifications::Dispatcher).to have_received(:deliver).once.with(
      to: user_a.phone_number,
      body: a_string_including("TAG-1").and(satisfy { |body| !body.include?("TAG-2") })
    )
    expect(Notifications::Dispatcher).to have_received(:deliver).once.with(
      to: user_b.phone_number,
      body: a_string_including("TAG-2").and(satisfy { |body| !body.include?("TAG-1") })
    )
  end

  it "labels calving and estrus dates as estimates" do
    user = create(:user, :whatsapp_subscriber)
    animal = create(:animal, user: user, identification: "TAG-1")
    create(:event, :breeding, animal: animal, occurred_on: Date.current)
    create(:event, :breeding, animal: animal, occurred_on: Date.current,
                              pregnancy_check_result: "confirmed", pregnancy_checked_on: Date.current)

    described_class.perform_now(window_start, 300.days.from_now.to_date)

    expect(Notifications::Dispatcher).to have_received(:deliver).once.with(
      to: user.phone_number,
      body: a_string_matching(/calving.*estimate/i).and(a_string_matching(/estrus.*estimate/i))
    )
  end

  it "does not re-send on a second run for the same window" do
    user = create(:user, :whatsapp_subscriber)
    animal = create(:animal, user: user, identification: "TAG-1")
    create(:event, :vaccination, animal: animal, due_on: 3.days.from_now.to_date)

    described_class.perform_now(window_start, window_end)
    described_class.perform_now(window_start, window_end)

    expect(Notifications::Dispatcher).to have_received(:deliver).once
    expect(ReminderSent.where(user: user, window_start: window_start, window_end: window_end).count).to eq(1)
  end
end
