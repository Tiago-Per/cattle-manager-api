class Animal < ApplicationRecord
  enum :category, { calf: "calf", heifer: "heifer", cow: "cow", bull: "bull", steer: "steer" }
  enum :sex, { male: "male", female: "female" }
  enum :status, { active: "active", sold: "sold", deceased: "deceased" }

  FEMALE_ONLY_CATEGORIES = %w[heifer cow].freeze
  MALE_ONLY_CATEGORIES = %w[bull steer].freeze

  validates :identification, presence: true, uniqueness: true
  validates :category, presence: true
  validates :sex, presence: true
  validates :status, presence: true

  validate :category_matches_sex
  validate :birth_date_not_in_the_future

  private

  def category_matches_sex
    return if category.blank? || sex.blank?

    if FEMALE_ONLY_CATEGORIES.include?(category) && !female?
      errors.add(:category, "#{category} is female-only")
    elsif MALE_ONLY_CATEGORIES.include?(category) && !male?
      errors.add(:category, "#{category} is male-only")
    end
  end

  def birth_date_not_in_the_future
    return if birth_date.blank?

    errors.add(:birth_date, "can't be in the future") if birth_date > Date.current
  end
end
