class Event < ApplicationRecord
  belongs_to :animal

  enum :event_type, { vaccination: "vaccination", weight: "weight", breeding: "breeding" }

  CALVING_GESTATION_DAYS = 283
  ESTRUS_CYCLE_DAYS = 21

  validates :event_type, presence: true
  validates :occurred_on, presence: true

  validate :occurred_on_not_in_the_future
  validate :weight_kg_presence
  validate :product_name_presence
  validate :sire_identification_presence
  validate :due_on_only_for_vaccination

  scope :calving_due_between, lambda { |from, to|
    breeding.where(
      "(occurred_on + INTERVAL '#{CALVING_GESTATION_DAYS} days') BETWEEN ? AND ?", from, to
    )
  }

  scope :estrus_due_between, lambda { |from, to|
    breeding.where(
      "(occurred_on + INTERVAL '#{ESTRUS_CYCLE_DAYS} days') BETWEEN ? AND ?", from, to
    )
  }

  def expected_calving_date
    return nil unless breeding? && occurred_on.present?

    occurred_on + CALVING_GESTATION_DAYS.days
  end

  def expected_estrus_date
    return nil unless breeding? && occurred_on.present?

    occurred_on + ESTRUS_CYCLE_DAYS.days
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
end
