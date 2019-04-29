class Versions::ScreenshotsVersion < Version
  KEY = 'screenshots'
  Actions = Types::Strict::Symbol
    .constructor(&:to_sym)
    .enum(:upload, :reposition, :delete)

  def action
    Actions[item_diff['action']]
  end

  def screenshots
    @screenshots ||= fetch_screenshots(
      action == Actions[:reposition] ? item_diff[KEY][1] : item_diff[KEY]
    )
  end

  def screenshots_prior
    @screenshots_prior ||= fetch_screenshots(
      action == Actions[:reposition] ? item_diff[KEY][0] : raise(NotImplementedError)
    )
  end

  def apply_changes
    case action
      when Actions[:upload] then upload_screenshots
      when Actions[:reposition] then reposition_screenshots
      when Actions[:delete] then delete_screenshots
    end
  end

  def rollback_changes
    raise NotImplementedError
  end

  def cleanup
    screenshots.each(&:destroy) if action == Actions[:upload]
  end

private

  def upload_screenshots
    screenshots.each(&:mark_accepted)
  end

  def delete_screenshots
    screenshots.each(&:mark_deleted)
  end

  def reposition_screenshots
    screenshots.each do |screenshot|
      index = item_diff[KEY][1].index(screenshot.id)
      screenshot.update(
        position: index || Versioneers::ScreenshotsVersioneer::DEFAULT_POSITION
      )
    end
  end

  def fetch_screenshots ids
    Screenshot
      .includes(:anime)
      .where(id: ids)
      .sort_by { |v| Array(ids).index v.id }
  end
end
