module Routing
  extend ActiveSupport::Concern
  include Rails.application.routes.url_helpers

  included do
    def shiki_domain
      if Rails.env.test?
        'test.host'
      elsif (Draper::ViewContext.current.request.try(:host) || 'test.host') == 'test.host'
        Site::DOMAIN
      else
        Draper::ViewContext.current.request.host
      end
    end

    def default_url_options
      ApplicationController.default_url_options.merge(host: shiki_domain)
    end
  end

  def topic_url topic, format = nil
    if topic.instance_of? NoTopic
      db_entry_path topic.linked

    elsif topic.kind_of?(User)
      profile_url topic, subdomain: false

    elsif topic.kind_of?(Topics::EntryTopics::ContestTopic) ||
        (topic.news? && !topic.generated?) || topic.review?

      forum_topic_url(
        id: topic,
        forum: topic.forum,
        linked: nil,
        format: format,
        subdomain: false
      )

    else
      forum_topic_url(
        id: topic,
        forum: topic.forum,
        linked_type: topic.linked.class.name.underscore,
        linked_id: topic.linked.to_param,
        format: format,
        subdomain: false
      )
    end
  end

  def forum_url forum, linked = nil
    if linked
      forum_topics_url forum,
        linked_id: linked.to_param,
        linked_type: linked.class.name.underscore
    else
      forum_topics_url forum
    end
  end

  def camo_url image_url
    @camo_urls ||= {}
    @camo_urls[image_url] = begin
      port = ':5566' if Rails.env.development?
      "//#{shiki_domain}#{port}/camo/#{camo_digest image_url}?url=#{image_url}"
    end
  end

private

  def db_entry_path db_entry
    public_send "#{db_entry.class.name.underscore}_path", db_entry
  end

  def camo_digest url
    OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new('sha1'),
      Rails.application.secrets[:camo][:key],
      url
    )
  end
end
