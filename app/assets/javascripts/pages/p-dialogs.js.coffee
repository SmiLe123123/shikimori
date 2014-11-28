@on 'page:load', 'dialogs_index', 'dialogs_show', ->
  $('.b-dialog.unprocessed').shiki_dialog()
  $('.b-message.unprocessed').shiki_message()

  $('.l-page').on 'postloader:success', '.b-postloader', (e, $data) ->
    $('.b-dialog.unprocessed', $data).shiki_dialog()
    $('.b-message.unprocessed', $data).shiki_message()
