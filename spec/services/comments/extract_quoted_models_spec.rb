describe Comments::ExtractQuotedModels do
  subject { described_class.call text }

  context 'no text' do
    let(:text) { nil }
    it do
      is_expected.to eq OpenStruct.new(
        comments: [],
        users: []
      )
    end
  end

  context 'quote' do
    let(:topic) { create :topic, user: user }
    let(:text) { "[quote=200778;#{user.id};test2]" }
    it do
      is_expected.to eq OpenStruct.new(
        comments: [],
        users: [user]
      )
    end
  end

  context 'mention' do
    let(:topic) { create :topic, user: user }
    let(:text) { "[user=#{user.id}]" }
    it do
      is_expected.to eq OpenStruct.new(
        comments: [],
        users: [user]
      )
    end
  end

  context 'comment reply' do
    let(:comment) { create :comment, user: user }
    let(:text) { "[comment=#{comment.id}]" }

    it do
      is_expected.to eq OpenStruct.new(
        comments: [comment],
        users: [user]
      )
    end
  end

  context 'comment quote' do
    let(:comment) { create :comment, user: user }
    let(:text) { "[quote=c#{comment.id};#{user.id};test2]" }

    it do
      is_expected.to eq OpenStruct.new(
        comments: [comment],
        users: [user]
      )
    end
  end

  context 'markdown quote' do
    let(:comment) { create :comment, user: user }
    let(:text) { ">?c#{comment.id};#{user.id};test2" }

    it do
      is_expected.to eq OpenStruct.new(
        comments: [comment],
        users: [user]
      )
    end
  end

  describe 'multiple entries' do
    let(:comment_1) { create :comment, user: user }
    let(:comment_2) { create :comment, user: user }
    let(:user_2) { create :user }

    context 'comment quote' do
      context 'single user' do
        let(:text) do
          <<-TEXT
            [comment=#{comment_1.id}]test[/comment]
            [comment=#{comment_1.id}]test[/comment]
            [comment=#{comment_2.id}]test[/comment]
          TEXT
        end

        it do
          is_expected.to eq OpenStruct.new(
            comments: [comment_1, comment_2],
            users: [user]
          )
        end
      end

      context 'multiple users' do
        let(:comment_3) { create :comment, user: user_2 }

        let(:text) do
          <<-TEXT
            [comment=#{comment_1.id}]test[/comment]
            [comment=#{comment_1.id}]test[/comment]
            [comment=#{comment_2.id}]test[/comment]
            [comment=#{comment_3.id}]test[/comment]
          TEXT
        end

        it do
          is_expected.to eq OpenStruct.new(
            comments: [comment_1, comment_2, comment_3],
            users: [user, user_2]
          )
        end
      end
    end

    context 'markdown quote' do
      context 'single user' do
        let(:text) do
          <<~TEXT
            >?c#{comment_1.id};#{user.id};chernilnaya_dusha
            > zxc
            rtry

            >?c#{comment_2.id};#{user.id};Scolopendromorph
            > qwe
            sdf
          TEXT
        end

        it do
          is_expected.to eq OpenStruct.new(
            comments: [comment_1, comment_2],
            users: [user]
          )
        end
      end

      context 'multiple users' do
        let(:comment_2) { create :comment, user: user_2 }

        let(:text) do
          <<~TEXT
            >?c#{comment_1.id};#{user.id};chernilnaya_dusha
            > zxc
            >?c#{comment_1.id};#{user.id};chernilnaya_dusha
            > etr
            rtry

            >?c#{comment_2.id};#{user_2.id};Scolopendromorph
            > qwe
            sdf
          TEXT
        end

        it do
          is_expected.to eq OpenStruct.new(
            comments: [comment_1, comment_2],
            users: [user, user_2]
          )
        end
      end
    end
  end
end
