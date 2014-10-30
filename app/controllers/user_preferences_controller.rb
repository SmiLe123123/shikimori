class UserPreferencesController < ProfilesController
  def update
    if @user.preferences.update user_preferences_params
      @user.update user_params if params[:user].present?
      redirect_to user_settings_path(@user, params[:page]), notice: 'Изменения сохранены'

    else
      flash[:alert] = 'Изменения не сохранены!'
      params[:type] = 'settings'
      show
    end
  end

private
  def user_preferences_params
    params.require(:user_preferences).permit(
      :anime_in_profile, :manga_in_profile,
      :statistics_in_profile, :comments_in_profile, :statistics_start_on,
      :page_background, :page_border, :body_background, :about_on_top, :about,
      :show_hentai_images, :show_social_buttons, :show_smileys, :menu_contest,
      :russian_genres, :russian_names, :mylist_in_catalog, :postload_in_catalog,
      :profile_privacy, :volumes_in_manga
    )
  end
end
