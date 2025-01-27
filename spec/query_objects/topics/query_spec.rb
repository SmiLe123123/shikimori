describe Topics::Query do
  subject(:query) { Topics::Query.fetch locale, is_censored_forbidden }

  let(:locale) { :ru }
  let(:is_censored_forbidden) { false }

  let(:all_sticky_topics) do
    [
      offtopic_topic,
      site_rules_topic,
      description_of_genres_topic,
      ideas_and_suggestions_topic,
      site_problems_topic,
      contests_proposals_topic,
      socials_topic
    ]
  end

  describe '#result' do
    context 'domain matches topic locale' do
      it { is_expected.to eq all_sticky_topics }
    end

    context 'domain does not match topic locale' do
      let(:locale) { :en }
      it { is_expected.to be_empty }
    end
  end

  describe '#by_forum' do
    subject { query.by_forum critiques_forum, user, is_censored_forbidden }
    let!(:critique) { create :critique, :with_topics }

    it { is_expected.to eq [critique.topic(locale)] }
  end

  describe '#by_linked' do
    subject { query.by_linked linked }

    context 'not club' do
      let(:linked) { create :anime }
      let!(:topic_1) { create :topic, linked: linked }
      let!(:topic_2) { create :topic }
      it { is_expected.to eq [topic_1] }
    end

    context 'club' do
      let!(:linked) { create :club, :with_topics, is_censored: true }
      let!(:club_page) { create :club_page, club: linked }
      let!(:club_page_topic) do
        create :club_page_topic,
          linked: club_page,
          updated_at: 9.days.ago,
          comments_count: club_page_topic_comments_count
      end
      let!(:club_user_topic) do
        create :club_user_topic,
          linked: club_page,
          updated_at: 8.days.ago
      end

      context 'wo comments' do
        let(:club_page_topic_comments_count) { 0 }
        it { is_expected.to eq [club_user_topic] }
      end

      context 'with comments' do
        let(:club_page_topic_comments_count) { 1 }
        before do
          linked
            .topic(locale)
            .update_columns(comments_count: 1, updated_at: 15.days.ago)
        end

        it do
          is_expected.to eq [
            club_user_topic,
            club_page_topic,
            linked.topic(locale)
          ]
        end
      end
    end
  end

  describe '#search' do
    let!(:topic_1) { create :topic, id: 1 }
    let!(:topic_2) { create :topic, id: 2 }
    let!(:topic_3) { create :topic, id: 3 }
    let!(:topic_en) { create :topic, id: 4, locale: :en }

    subject { query.search phrase, forum, user, locale }

    let(:phrase) { 'test' }
    let(:forum) { seed :animanga_forum }
    let(:user) { nil }
    let(:locale) { 'ru' }
    let(:topics) { [topic_1, topic_2] }

    before do
      allow(Topics::SearchQuery).to receive(:call).with(
        scope: anything,
        phrase: phrase,
        forum: forum,
        user: user,
        locale: locale
      ).and_return(topics)
    end

    it { is_expected.to eq topics }
  end

  describe '#as_views' do
    let(:is_preview) { true }
    let(:is_mini) { true }

    subject(:views) { query.as_views(is_preview, is_mini) }

    it do
      expect(views).to have(7).items
      expect(views.first).to be_kind_of Topics::View
      expect(views.first.is_mini).to eq true
      expect(views.first.is_preview).to eq true
    end

    context 'preview' do
      let(:is_preview) { false }
      it do
        expect(views.first.is_mini).to eq true
        expect(views.first.is_preview).to eq false
      end
    end

    context 'mini' do
      let(:is_mini) { false }
      it do
        expect(views.first.is_mini).to eq false
        expect(views.first.is_preview).to eq true
      end
    end
  end
end
