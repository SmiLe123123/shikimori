class CommentsController < ShikimoriController
  include CommentHelper

  def show # rubocop:disable AbcSize, MethodLength
    og noindex: true
    comment = Comment.find_by(id: params[:id]) || NoComment.new(params[:id])

    if comment.commentable.is_a?(Topic) && comment.commentable.linked.is_a?(Club)
      Clubs::RestrictCensored.call(
        club: comment.commentable.linked,
        current_user: current_user
      )
    end

    @view = Comments::View.new comment, false

    if comment.is_a? NoComment
      render :missing
    else
      og(
        image: comment.user.avatar_url(160),
        page_title: i18n_t('comment_by', nickname: comment.user.nickname),
        description: comment.body.gsub(%r{\[[/\w_ =-]+\]}, '')
      )

      render :show
    end
  end

  def tooltip
    show
  end

  def reply
    comment = Comment.find params[:id]
    @view = Comments::View.new comment, true
    render :show
  end

  def edit
    @comment = Comment.find params[:id]
  end

  # все комментарии сущности до определённого коммента
  def fetch
    comment = Comment.find(params[:comment_id])
    topic = params[:topic_type].constantize.find(params[:topic_id])

    raise CanCan::AccessDenied unless comment.commentable == topic

    from = params[:skip].to_i
    to = [params[:limit].to_i, 100].min

    query = topic
      .comments
      .includes(:user, :topic)
      .offset(from)
      .limit(to)

    query.where! is_summary: true if params[:is_summary]

    @collection = query
      .decorate
      .reverse

    render :collection, formats: :json
  end

  # список комментариев по запросу
  def chosen
    comments = Comment
      .where(id: params[:ids].split(',').map(&:to_i))
      .includes(:user, :commentable)
      .limit(100)
      .decorate

    @collection = params[:order] ? comments.reverse : comments

    render :collection, formats: :json
  end

  def preview
    @comment = Comment.new(preview_params).decorate

    # это может быть предпросмотр не просто текста, а описания к аниме или манге
    if params[:comment][:target_type] && params[:comment][:target_id]
      @comment = DescriptionComment.new(@comment,
        params[:comment][:target_type], params[:comment][:target_id])
    end

    render @comment
  end

  def smileys
    render partial: 'comments/smileys'
  end

private

  def faye
    FayeService.new current_user, faye_token
  end

  def preview_params
    params
      .require(:comment)
      .permit(:body, :is_summary, :is_offtopic, :commentable_id, :commentable_type, :user_id)
      .tap do |comment|
        comment[:user_id] ||= current_user.id
        comment[:body] = Banhammer.instance.censor comment[:body], nil
      end
  end
end
