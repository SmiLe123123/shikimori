describe VersionsPolicy do
  let(:version_allowed) { described_class.version_allowed? user, version }
  let(:change_allowed) { described_class.change_allowed? user, item, field }

  let(:version) do
    build :version, item: item, item_diff: item_diff, user: author
  end
  let(:author) { user }
  let(:user) { seed :user }

  let(:item) { build_stubbed :anime, field => change_from }
  let(:item_diff) do
    {
      field => [change_from, change_to]
    }
  end
  let(:field) { :russian }
  let(:change_from) { 'a' }
  let(:change_to) { 'b' }

  it { expect(version_allowed).to eq true }
  it { expect(change_allowed).to eq true }

  context 'no user' do
    let(:user) { nil }
    it { expect(version_allowed).to eq false }
    it { expect(change_allowed).to eq false }
  end

  context 'user banned' do
    before { user.read_only_at = 1.hour.from_now }
    it { expect(version_allowed).to eq false }
    it { expect(change_allowed).to eq false }
  end

  context 'not_trusted_version_changer' do
    before { user.roles = %i[not_trusted_version_changer] }
    it { expect(version_allowed).to eq false }
    it { expect(change_allowed).to eq false }
  end

  context 'not_trusted_names_changer' do
    before { user.roles = %i[not_trusted_names_changer] }

    context 'not name field' do
      let(:field) { 'description_ru' }
      it { expect(version_allowed).to eq true }
      it { expect(change_allowed).to eq true }
    end

    context 'name field' do
      let(:field) do
        (
          Abilities::VersionNamesModerator::MANAGED_FIELDS -
            Anime::RESTRICTED_FIELDS
        ).sample
      end

      context 'not DbEntry model' do
        let(:item) { build_stubbed :video }
        it { expect(version_allowed).to eq true }
        it { expect(change_allowed).to eq true }
      end

      context 'DbEntry model' do
        it { expect(version_allowed).to eq false }
        it { expect(change_allowed).to eq false }
      end
    end
  end

  context 'not_trusted_texts_changer' do
    before { user.roles = %i[not_trusted_texts_changer] }

    context 'not text field' do
      let(:field) { 'russian' }
      it { expect(version_allowed).to eq true }
      it { expect(change_allowed).to eq true }
    end

    context 'text field' do
      let(:field) do
        (
          Abilities::VersionTextsModerator::MANAGED_FIELDS -
            Anime::RESTRICTED_FIELDS
        ).sample
      end

      context 'not DbEntry model' do
        let(:item) { build_stubbed :video }
        it { expect(version_allowed).to eq true }
        it { expect(change_allowed).to eq true }
      end

      context 'DbEntry model' do
        it { expect(version_allowed).to eq false }
        it { expect(change_allowed).to eq false }
      end
    end
  end

  context 'not_trusted_fansub_changer' do
    before { user.roles = %i[not_trusted_fansub_changer] }

    context 'not fansub field' do
      let(:field) { 'russian' }
      it { expect(version_allowed).to eq true }
      it { expect(change_allowed).to eq true }
    end

    context 'fansub field' do
      let(:field) { Abilities::VersionFansubModerator::MANAGED_FIELDS.sample }

      context 'not DbEntry model' do
        let(:item) { build_stubbed :video }
        it { expect(version_allowed).to eq true }
        it { expect(change_allowed).to eq true }
      end

      context 'DbEntry model' do
        it { expect(version_allowed).to eq false }
        it { expect(change_allowed).to eq false }
      end
    end
  end

  context 'not matched author' do
    let(:author) { user_2 }
    it { expect(version_allowed).to eq false }
  end

  context 'changed restricted field' do
    context 'from nil to value' do
      let(:field) { %i[name image].sample }
      let(:change_from) { nil }

      it { expect(version_allowed).to eq true }
      it { expect(change_allowed).to eq true }
    end

    context 'from value to value' do
      let(:field) { :name }
      it { expect(version_allowed).to eq false }
      it { expect(change_allowed).to eq false }
    end
  end
end
