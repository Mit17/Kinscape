# == Schema Information
#
# Table name: stories
#
#  id                  :integer          not null, primary key
#  title               :string           default(""), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  date                :string           default(""), not null
#  description         :text             default(""), not null
#  user_id             :integer          not null
#  tags                :string           default([]), is an Array
#  cover_image_id      :integer
#  start_year          :string
#  start_month         :string
#  start_day           :string
#  end_year            :string
#  end_month           :string
#  end_day             :string
#  is_range            :boolean          default(FALSE)
#  date_as_text        :string           default(""), not null
#  comments_count      :integer          default(0), not null
#  appreciations_count :bigint           default(0)
#  sections_count      :integer          default(0), not null
#  contributors_count  :integer          default(0), not null
#  uuid                :bigint
#  aws                 :boolean
#  original_story_id   :integer
#

class Story < ApplicationRecord
  include Uid

  acts_as_readable on: :updated_at

  belongs_to :user
  belongs_to :original_story, class_name: 'Story', optional: true
  has_many :shared_stories,
           class_name: 'Story',
           foreign_key: :original_story_id,
           inverse_of: :original_story,
           dependent: :nullify
  with_options dependent: :destroy do
    has_many :comments, -> { order(:created_at) }, as: :commentable, inverse_of: :commentable
    has_many :sections, -> { order(:position) }, inverse_of: :story
    has_many :publications
    has_many :not_private_publications, -> { not_private_type }, class_name: 'Publication', inverse_of: :story
    has_many :appreciations, as: :appreciable
  end
  has_many :media_files, through: :sections
  has_many :families, through: :publications
  has_many :family_members, through: :families, source: :users
  has_many :contributors,
           ->(story) { where.not(sections: { author_id: story.user_id }).distinct.reorder(nil) },
           through: :sections,
           source: :author
  has_one_attached :cover

  validates :user, presence: true
  validates :title, presence: true
  validates :start_year, :start_month, :start_day,
            :end_year, :end_month, :end_day,
            presence: true, if: -> { is_range }
  validate :check_year_of_range, if: -> { is_range }
  validate :check_month_of_range, if: -> { is_range }
  validate :check_day_of_range, if: -> { is_range }

  delegate :avatar, :name, to: :user, prefix: true

  before_save :populate_date_as_text
  after_commit :process_cover_variant

  accepts_nested_attributes_for :sections
  accepts_nested_attributes_for :publications

  scope :with_comments, -> { includes(comments: :user).order('comments.created_at DESC') }
  scope :draft, -> { left_outer_joins(:publications).where(publications: { id: nil }) }
  scope :published, -> {
    joins(:not_private_publications).where(publications: { publish_on: [nil, ..Time.zone.today] })
  }

  def populate_date_as_text
    date_attributes = %w{start_year start_month start_day
                         end_year end_month end_day}
    return if (date_attributes & changed_attribute_names_to_save).blank?

    if is_range
      s_year  = start_year
      e_month = end_month

      if start_year == end_year
        s_year  = nil
        e_month = nil if start_month == end_month
      end

      self.date_as_text = [
        format_date(s_year, start_month, start_day),
        format_date(end_year, e_month, end_day)
      ].reject(&:blank?).join(' - ')
    else
      self.date_as_text = format_date(start_year, start_month, start_day)
    end
  end

  def format_date(year, month, day)
    if day.blank?
      [month, year].reject(&:blank?).join(' ')
    else
      [[month, (day.to_i.try :ordinalize)].compact.join(' '), year]
        .reject(&:blank?).join(', ')
    end
  end

  def self.chronological
    order(created_at: :desc)
  end

  def cover_url(size: nil)
    return Rails.application.routes.url_helpers.rails_blob_url(cover, only_path: true) if Rails.env.test?

    if cover.attached? && size
      return Rails.application.routes.url_helpers.rails_representation_url(
        cover.variant(resize_to_limit: IMAGE_SIZE[size]),
        only_path: true
      )
    end
    Rails.application.routes.url_helpers.rails_blob_url(cover, only_path: true) if cover.attached?
  rescue StandardError
    nil
  end

  def story
    self
  end

  def time_capsule
    @time_capsule ||= publications.first
  end

  def time_capsule?
    !time_capsule&.publish_on.nil?
  end

  def time_capsule_released?
    time_capsule? && time_capsule.publish_on <= Time.zone.now
  end

  def delete_all_contents_by_author(author)
    sections.where(author: author).destroy_all
    appreciations.where(user: author).destroy_all
    comments.where(user: author).destroy_all
  end

  private

  def check_year_of_range
    start_year.to_i > end_year.to_i &&
      errors.add(:end_year, 'can\'t be smaller than start year')
  end

  def check_month_of_range
    month_num(start_month).zero? && errors.add(:start_month, 'Invalid month')
    month_num(end_month).zero? && errors.add(:end_month, 'Invalid month')

    start_year.to_i == end_year.to_i &&
      month_num(start_month) > month_num(end_month) &&
      errors.add(:end_month, 'can\'t be smaller than start month')
  end

  def check_day_of_range
    start_year.to_i == end_year.to_i &&
      month_num(start_month) == month_num(end_month) &&
      start_day.to_i > end_day.to_i &&
      errors.add(:end_day, 'can\'t be smaller than start day')
  end

  def month_num(month)
    Date::MONTHNAMES.index(month&.capitalize)
  end

  def process_cover_variant
    return unless cover.attached?

    ProcessImageVariantJob.perform_later(self, :cover, [:medium])
  end
end
