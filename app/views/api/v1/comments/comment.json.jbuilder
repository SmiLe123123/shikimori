json.id @resource.id
json.content JsExports::Supervisor.instance.sweep(
  render(
    partial: 'comments/comment',
    object: @resource.decorate,
    formats: :html
  )
)

json.JS_EXPORTS JsExports::Supervisor.instance.export(current_user)
