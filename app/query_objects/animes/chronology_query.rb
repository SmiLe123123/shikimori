class Animes::ChronologyQuery
  pattr_initialize :entry

  IGNORED_IN_RELATIONS = {
    anime: [],
    manga: [81_927]
  }
  FUTURE_DATE = 50.years.from_now

  def fetch
    @entry.class
      .where(id: chronology_ids)
      .sort_by { |v| [v.aired_on || FUTURE_DATE, v.id] }
      .reverse
  end

  def links
    related_entries.flat_map { |_source_id, related| related }
  end

private

  def chronology_ids
    related_entries.keys + related_entries.values.flatten.map(&:anime_id)
  end

  def related_entries
    @related_entries ||= fetch_related [@entry.id], {}
  end

  def fetch_related ids, relations # rubocop:disable AbcSize, MethodLength
    ids_to_fetch = ids - relations.keys

    fetched_ids = groupped_relation(ids_to_fetch).flat_map do |source_id, group|
      relations[source_id] = group.select do |relation|
        # puts "#{source_id}\t#{relation.anime_id}\t#{banned?(source_id, relation)}\t#{relations.keys.join(',')}"
        !banned?(source_id, relation) &&
          relations.keys.none? { |v| banned? v, relation }
      end

      relations[source_id] # .select { |v| v.relation != 'Character' }
        .map { |v| v[related_field] }
    end

    if fetched_ids.any?
      fetch_related fetched_ids, relations
    else
      relations
    end
  end

  def groupped_relation ids
    query = related_klass
      .where(source_id: ids)
      .where("#{related_field} is not null")

    unless @with_specials
      base_class = @entry.class.base_class
      query = query.joins("
        inner join #{@entry.class.table_name} on
          #{@entry.class.table_name}.id=#{base_class.name.downcase}_id
        ")
    end

    query.group_by(&:source_id)
  end

  def anime?
    @entry.anime?
  end

  def related_klass
    anime? ? RelatedAnime : RelatedManga
  end

  def related_field
    anime? ? :anime_id : :manga_id
  end

  def banned? source_id, relation
    if IGNORED_IN_RELATIONS[anime? ? :anime : :manga].include?(source_id)
      return true
    end

    item_relations =
      if anime?
        relations.anime(source_id)
      else
        relations.manga(source_id)
      end

    item_relations.include?(anime? ? relation.anime_id : relation.manga_id)
  end

  def relations
    Animes::BannedRelations.instance
  end
end
