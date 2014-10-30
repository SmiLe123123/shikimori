(($) ->
  $.fn.extend
    completable: (default_text, success_callback, $anchor) ->
      @each ->
        $element = $(@)
        if default_text
          $element.defaultText default_text

        $element
          .on 'result', (e, entry) ->
            if entry
              entry.id = entry.data
              entry.name = entry.value
              $element.trigger 'autocomplete:success', [entry]

          .autocomplete 'data-autocomplete',
            #autoFill: true,
            cacheLength: 10
            delay: 10
            formatItem: (entry) ->
              entry.label

            matchContains: 1
            matchSubset: 1
            minChars: 2
            dataType: 'JSON'
            parse: (data) ->
              $element.trigger 'parse'
              data.reverse()

            $anchor: $anchor
            selectFirst: false

    completable_variant: ->
      @each ->
        $(@).completable()
        $(@).on 'autocomplete:success', (e, entry) ->
          $variants = $(@).parent().find('.variants')
          variant_name = $(@).data('variant_name')
          return if $variants.find("[value=\"#{entry.id}\"]").exists()

          $entry = $(
            '<div class="variant">' +
              '<input type="checkbox" name="'+variant_name+'" value="'+entry.id+'" checked="true" />' +
              '<a href="'+entry.url+'" class="bubbled">'+entry.name+'</a>' +
            '</div>')
            .appendTo($variants)
            .process()

          @value = ''
) jQuery
