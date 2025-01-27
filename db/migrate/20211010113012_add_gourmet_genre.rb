class AddGourmetGenre < ActiveRecord::Migration[5.2]
  def up
    return if Rails.env.test?

    %i[anime manga].each_with_index do |kind, index|
      Genre.create!(
        name: 'Gourmet',
        russian: 'Гурман',
        position: Genre.find_by(name: 'Slice of Life', kind: kind).position,
        kind: kind,
        seo: 99,
        mal_id: 47
      )
    end
  end

  def down
    Genre.where(mal_id: 47).destroy_all
  end
end
