class BbCodes::Tags::CommentTag
  include Singleton
  extend DslAttribute

  dsl_attribute :klass, Comment
  dsl_attribute :user_field, :user

  def bbcode_regexp
    @regexp ||= %r{
      \[#{name_regexp}=(?<id>\d+) (?<quote>\ quote)?\]
        (?<text> .*? )
      \[/#{name_regexp}\]
      |
      \[#{name_regexp}=(?<id>\d+)\]
    }mix
  end

  def id_regexp
    @id_regexp ||= /\[#{name_regexp}=(\d+)/
  end

  def format text
    entries = fetch_entries text

    text.gsub(bbcode_regexp) do
      entry_id = $LAST_MATCH_INFO[:id]
      entry = entries[entry_id.to_i]

      if entry
        bbcode_to_html(
          entry,
          $LAST_MATCH_INFO[:text],
          $LAST_MATCH_INFO[:quote].present?
        )
      else
        not_found_to_hmtl entry_id, $LAST_MATCH_INFO[:text]
      end
    end
  end

private

  def bbcode_to_html entry, text, is_quoted
    user = entry&.send(self.class::USER_FIELD) if is_quoted || text.blank?

    author_name = text.presence || user&.nickname || NOT_FOUND
    url = entry_url entry
    css_classes = css_classes entry, user, is_quoted
    author_html = author_html is_quoted, user, author_name

    "[url=#{url} #{css_classes}]#{author_html}[/url]"
  end

  def not_found_to_hmtl entry_id, text
    "<span class='b-mention'>" +
      (text.present? ? text + ' ' : '') +
       "<del>404 ID=#{entry_id}</del></span>"
  end

  def entry_url entry
    UrlGenerator.instance.send :"#{name}_url", entry
  end

  def css_classes entry, user, is_quoted
    [
      ('bubbled' if entry),
      'b-mention',
      ('b-user16' if user && is_quoted)
    ].compact.join(' ')
  end

  def author_html is_quoted, user, author_name
    if is_quoted
      quoteed_author_html user, author_name
    else
      author_name
    end
  end

  def quoteed_author_html user, author_name
    return "<span>#{author_name}</span>" unless user&.avatar&.present?

    <<-HTML.squish
      <img
        src="#{user.avatar_url 16}"
        srcset="#{user.avatar_url 32} 2x"
        alt="#{author_name}"
      /><span>#{author_name}</span>
    HTML
  end

  def fetch_entries text
    entry_ids = text.scan(id_regexp).map { |v| v[0].to_i }

    klass
      .where(id: entry_ids)
      .includes(self.class::USER_FIELD)
      .index_by(&:id)
  end

  def name
    klass.base_class.name.downcase
  end

  def name_regexp
    name
  end
end
