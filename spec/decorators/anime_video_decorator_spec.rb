describe AnimeVideoDecorator, type: :controller do
  subject(:decorator) { AnimeVideoDecorator.new video }

  describe '#player_html', focus: true do
    subject { decorator.player_html }
    let(:video) { create :anime_video, url: url }

    context 'myvi.ru' do
      let(:url) { 'http://myvi.ru/video' }
      it { is_expected.to eq "<object><param name=\"movie\" value=\"#{url}\"></param><param name=\"allowFullScreen\" value=\"true\"></param><param name=\"allowScriptAccess\" value=\"always\"></param><embed src=\"#{url}\" type=\"application/x-shockwave-flash\" allowfullscreen=\"allowfullscreen\" allowScriptAccess=\"always\"></embed></object>" }
    end

    context 'sibnet.ru' do
      context 'with .swf?' do
        let(:url) { 'http://sibnet.ru/video/1.swf?' }
        it { is_expected.to eq "<object><param name=\"movie\" value=\"#{url}\"></param><param name=\"allowFullScreen\" value=\"true\"></param><param name=\"allowScriptAccess\" value=\"always\"></param><embed src=\"#{url}\" type=\"application/x-shockwave-flash\" allowfullscreen=\"allowfullscreen\" allowScriptAccess=\"always\"></embed></object>" }
      end

      context 'without .swf?' do
        let(:url) { 'http://sibnet.ru/video/1' }
        it { is_expected.to eq "<iframe src=\"#{url}\"></iframe>" }
      end
    end

    context 'vk' do
      let(:url) { 'http://www.vk.com?id=1' }
      it { is_expected.to eq "<iframe src=\"#{url}\"></iframe>" }
    end

    context 'rutube.ru' do
      context 'http://video.rutube.ru/7632871' do
        let(:url) { 'http://video.rutube.ru/7632871' }
        let(:expected_url) { "http://rutube.ru/play/embed/7632871" }
        it { is_expected.to eq "<iframe src=\"#{expected_url}\" frameborder=\"0\" webkitAllowFullScreen=\"true\" mozallowfullscreen=\"true\" allowfullscreen=\"allowfullscreen\"></iframe>" }
      end

      context 'http://rutube.ru/play/embed/7630847' do
        let(:url) { 'http://rutube.ru/play/embed/7630847' }
        it { is_expected.to eq "<iframe src=\"#{url}\"></iframe>" }
      end
    end
  end

  describe '#player_url' do
    subject { decorator.player_url }
    let(:video) { create :anime_video, url: url }
    let(:url) { 'http://www.vk.com?id=1' }

    it { is_expected.to eq url }
  end

  describe '#user_rate & #in_list? & #watched?' do
    before { allow(decorator).to receive(:h).and_return auth_double }
    let(:auth_double) { double current_user: user, user_signed_in?: user_signed_in }

    context 'authenticated' do
      let(:user_signed_in) { true }
      let(:user) { create :user }

      context 'with user rate' do
        let!(:user_rate) { create :user_rate, target: video.anime, user: user, episodes: episodes }
        let(:episodes) { 99 }

        its(:user_rate) { should eq user_rate }
        its(:in_list?) { should be_truthy }

        context 'watched episode' do
          its(:watched?) { should be_truthy }
        end

        context 'not watched episode' do
          let(:episodes) { 0 }
          its(:watched?) { should be_falsy }
        end
      end

      context 'without user rate' do
        its(:user_rate) { should be_nil }
        its(:in_list?) { should be_falsy }
        its(:watched?) { should be_falsy }
      end
    end

    context 'not authenticated' do
      let(:user) { }
      let(:user_signed_in) { false }

      its(:user_rate) { should be_nil }
      its(:in_list?) { should be_falsy }
      its(:watched?) { should be_falsy }
    end
  end
end
