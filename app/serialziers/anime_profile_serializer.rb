class AnimeProfileSerializer < AnimeSerializer
  attributes :rating, :english, :japanese, :synonyms, :kind, :aired_on, :released_on
  attributes :episodes, :episodes_aired, :duration, :score, :description, :description_html
  attributes :favoured?, :anons?, :ongoing?, :thread_id, :world_art_id

  has_many :genres
  has_many :studios

  has_one :user_rate

  def user_rate
    AnimeRateSerializer.new object.rate
  end

  def thread_id
    object.thread.id
  end
end
