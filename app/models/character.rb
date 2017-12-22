# frozen_string_literal: true

class Character < DbEntry
  include TopicsConcern
  include CollectionsConcern

  DESYNCABLE = %w[name japanese description_en image]

  update_index('characters#character') do
    self # if saved_change_to_title? || saved_change_to_forum_id?
  end

  has_many :person_roles, dependent: :destroy
  has_many :animes, -> { order :id }, through: :person_roles
  has_many :mangas, -> { order :id }, through: :person_roles
  has_many :people, through: :person_roles
  has_many :japanese_roles, -> { where role: 'Japanese' },
    class_name: PersonRole.name
  has_many :seyu, through: :japanese_roles, source: :person

  has_many :cosplay_gallery_links, as: :linked, dependent: :destroy
  has_many :cosplay_galleries, -> { where deleted: false, confirmed: true },
    through: :cosplay_gallery_links

  has_many :contest_winners,
    -> { where item_type: Character.name },
    foreign_key: :item_id,
    dependent: :destroy

  has_attached_file :image,
    styles: {
      original: ['225x350>', :jpg],
      preview: ['160x240>', :jpg],
      x96: ['96x150#', :jpg],
      x48: ['48x75#', :jpg]
    },
    url: '/system/characters/:style/:id.:extension',
    path: ':rails_root/public/system/characters/:style/:id.:extension',
    default_url: '/assets/globals/missing_:style.jpg'

  before_post_process { translit_paperclip_file_name :image }

  validates :image, attachment_content_type: { content_type: /\Aimage/ }

  # альтернативное имя "в кавычках"
  def altname
    fullname.present? ? fullname.gsub(/^.*?"|".*?$/, '') : nil
  end
end
