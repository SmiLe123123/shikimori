class Api::V1::StylesController < Api::V1::ApiController
  respond_to :json
  load_and_authorize_resource

  api :POST, '/styles', 'Create a style'
  param :style, Hash do
    param :css, String, required: true
    param :name, String, required: true
    param :owner_id, :number, required: true
    param :owner_type, %w(User Club), required: true
  end
  def create
    @resource.save
    respond_with @resource
  end

  api :PATCH, '/styles/:id', 'Update a style'
  api :PUT, '/styles/:id', 'Update a style'
  param :style, Hash do
    param :css, String, required: true
    param :name, String, required: true
  end
  def update
    @resource.update update_params
    respond_with @resource, location: nil
  end

  # AUTO GENERATED LINE: REMOVE THIS TO PREVENT REGENARATING
  api :DELETE, '/styles/:id', 'Destroy a style'
  def destroy
    @resource.destroy
    head 204
  end

private

  def create_params
    params.require(:style).permit(:owner_id, :owner_type, :name, :css)
  end

  def update_params
    params.require(:style).permit(:name, :css)
  end
end
