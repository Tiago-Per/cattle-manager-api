class Event < ApplicationRecord
  belongs_to :animal

  enum :event_type, { vaccination: "vaccination", weight: "weight", breeding: "breeding" }

  enum :pregnancy_check_result,
       { pending: "pending", confirmed: "confirmed", negative: "negative" },
       prefix: :pregnancy, validate: { allow_nil: true }

  CALVING_GESTATION_DAYS = 283
  ESTRUS_CYCLE_DAYS = 21

  validates :event_type, presence: true
  validates :occurred_on, presence: true

  validate :occurred_on_not_in_the_future
  validate :weight_kg_presence
  validate :product_name_presence
  validate :sire_identification_presence
  validate :due_on_only_for_vaccination
  validate :pregnancy_check_only_for_breeding
  validate :pregnancy_checked_on_rules

  before_validation :default_pregnancy_check_result

  scope :calving_due_between, lambda { |from, to|
    breeding.where(pregnancy_check_result: "confirmed").where(
      "(occurred_on + INTERVAL '#{CALVING_GESTATION_DAYS} days') BETWEEN ? AND ?", from, to
    )
  }

  scope :estrus_due_between, lambda { |from, to|
    breeding.where(pregnancy_check_result: [ nil, "pending", "negative" ]).where(
      "(occurred_on + INTERVAL '#{ESTRUS_CYCLE_DAYS} days') BETWEEN ? AND ?", from, to
    )
  }

  # Only estimated once the pregnancy is confirmed; pending and negative return nil.
  def expected_calving_date
    return nil unless breeding? && occurred_on.present?
    return nil unless pregnancy_confirmed?

    occurred_on + CALVING_GESTATION_DAYS.days
  end

  # Nil only when confirmed (a pregnant cow won't cycle); a negative result keeps the estimate.
  def expected_estrus_date
    return nil unless breeding? && occurred_on.present?
    return nil if pregnancy_confirmed?

    occurred_on + ESTRUS_CYCLE_DAYS.days
  end

  def as_json(options = {})
    json = super

    return json unless breeding?

    estimates = {
      "expected_calving_date" => expected_calving_date,
      "expected_estrus_date" => expected_estrus_date
    }.compact
    return json if estimates.empty?

    json["estimates"] = estimates.merge(
      "disclaimer" => "Estimated from average bovine values. Not a veterinary prediction."
    )
    json
  end

  private

  def occurred_on_not_in_the_future
    return if occurred_on.blank?

    errors.add(:occurred_on, "can't be in the future") if occurred_on > Date.current
  end

  def weight_kg_presence
    if weight? && weight_kg.blank?
      errors.add(:weight_kg, "can't be blank for a weight event")
    elsif !weight? && weight_kg.present?
      errors.add(:weight_kg, "can only be set for a weight event")
    end
  end

  def product_name_presence
    if vaccination? && product_name.blank?
      errors.add(:product_name, "can't be blank for a vaccination event")
    elsif !vaccination? && product_name.present?
      errors.add(:product_name, "can only be set for a vaccination event")
    end
  end

  def sire_identification_presence
    if breeding? && sire_identification.blank?
      errors.add(:sire_identification, "can't be blank for a breeding event")
    elsif !breeding? && sire_identification.present?
      errors.add(:sire_identification, "can only be set for a breeding event")
    end
  end

  def due_on_only_for_vaccination
    errors.add(:due_on, "can only be set for a vaccination event") if due_on.present? && !vaccination?
  end

  def default_pregnancy_check_result
    self.pregnancy_check_result = :pending if breeding? && pregnancy_check_result.nil?
  end

  def pregnancy_check_only_for_breeding
    return if breeding?

    errors.add(:pregnancy_check_result, "can only be set for a breeding event") if pregnancy_check_result.present?
    errors.add(:pregnancy_checked_on, "can only be set for a breeding event") if pregnancy_checked_on.present?
  end

  def pregnancy_checked_on_rules
    if pregnancy_pending?
      errors.add(:pregnancy_checked_on, "can't be set while the pregnancy check result is pending") if pregnancy_checked_on.present?
      return
    end

    return unless pregnancy_confirmed? || pregnancy_negative?

    if pregnancy_checked_on.blank?
      errors.add(:pregnancy_checked_on, "can't be blank when the pregnancy check result is confirmed or negative")
    elsif pregnancy_checked_on > Date.current
      errors.add(:pregnancy_checked_on, "can't be in the future")
    elsif occurred_on.present? && pregnancy_checked_on < occurred_on
      errors.add(:pregnancy_checked_on, "can't be before the breeding date")
    end
  end
end
