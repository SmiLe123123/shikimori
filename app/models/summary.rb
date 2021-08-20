class Summary < ApplicationRecord
  include AntispamConcern
  include Moderatable
  include Viewable

  antispam(
    interval: 1.minute,
    disable_if: -> { Rails.env.development? && user&.admin? },
    user_id_key: :user_id
  )

  belongs_to :user
  belongs_to :anime, optional: true
  belongs_to :manga, optional: true

  enumerize :tone, in: Types::Summary::Tone.values

  MIN_BODY_SIZE = 230

  validates :body,
    presence: true,
    length: { minimum: MIN_BODY_SIZE },
    unless: -> { @is_migration }
  validates :user_id,
    uniqueness: { scope: %i[anime_id] },
    if: :anime?
  validates :user_id,
    uniqueness: { scope: %i[manga_id] },
    if: :manga?

  validates :anime, presence: true, unless: :manga?
  validates :manga, presence: true, unless: :anime?

  scope :positive, -> { where tone: Types::Summary::Tone[:positive] }
  scope :neutral, -> { where tone: Types::Summary::Tone[:neutral] }
  scope :negative, -> { where tone: Types::Summary::Tone[:negative] }

  before_create :fill_is_written_before_release,
    if: -> { is_written_before_release.nil? }

  def html_body
    BbCodes::Text.call body
  end

  def anime?
    anime_id.present?
  end

  def manga?
    manga_id.present?
  end

  def db_entry
    anime? ? anime : manga
  end

  def db_entry_released_before?
    db_entry.released? &&
      (!db_entry.released_on || db_entry.released_on <= Time.zone.today)
  end

private

  def fill_is_written_before_release
    self.is_written_before_release = !db_entry_released_before?
  end
end