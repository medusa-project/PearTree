require 'test_helper'

class ItemsControllerTest < ActionDispatch::IntegrationTest

  def setup
    @item = items(:free_form_dir1_dir1_file1)
  end

  # binary()

  test 'binary() returns HTTP 200 for a valid filename' do
    @item = items(:compound_object_1001)
    get item_binary_path(@item, @item.binaries.first.filename)
    assert_response :ok
  end

  test 'binary() returns HTTP 404 for an invalid filename' do
    get item_binary_path(@item, 'bogus.jpg')
    assert_response :not_found
  end

  # iiif_annotation_list()

  test 'iiif_annotation_list() returns HTTP 200 for a valid item' do
    get item_iiif_annotation_list_path(@item, @item.repository_id)
    assert_response :ok
  end

  test 'iiif_annotation_list() returns HTTP 404 for an invalid item' do
    get item_iiif_annotation_list_path('bogus', 'bogus-name')
    assert_response :not_found
  end

  # iiif_canvas()

  test 'iiif_canvas() returns HTTP 200 for a valid item' do
    get item_iiif_canvas_path(@item, 'any-name')
    assert_response :ok
  end

  test 'iiif_canvas() returns HTTP 404 for an invalid item' do
    get item_iiif_canvas_path('bogus', 'any-name')
    assert_response :not_found
  end

  # iiif_image_resource()

  test 'iiif_image_resource() returns HTTP 200 for a valid item and a valid
  resource name' do
    get item_iiif_image_resource_path(@item, 'access')
    assert_response :ok
    get item_iiif_image_resource_path(@item, 'preservation')
    assert_response :ok
  end

  test 'iiif_image_resource() returns HTTP 404 for a valid item and an invalid
  resource name' do
    get item_iiif_image_resource_path(@item, 'bogus')
    assert_response :not_found
  end

  test 'iiif_image_resource() returns HTTP 404 for an invalid item' do
    get item_iiif_image_resource_path('bogus', 'access')
    assert_response :not_found
  end

  # iiif_layer()

  test 'iiif_layer() returns HTTP 200 for a valid item' do
    get item_iiif_layer_path(@item, @item)
    assert_response :ok
  end

  test 'iiif_layer() returns HTTP 404 for an invalid item' do
    get item_iiif_layer_path('bogus', 'bogus')
    assert_response :not_found
  end

  # iiif_manifest()

  test 'iiif_manifest() returns HTTP 200 for a valid item' do
    get item_iiif_manifest_path(@item, 'name-doesnt-matter')
    assert_response :ok
  end

  test 'iiif_manifest() returns HTTP 404 for an invalid item' do
    get item_iiif_manifest_path('bogus', 'name-doesnt-matter')
    assert_response :not_found
  end

  # iiif_media_sequence()

  test 'iiif_media_sequence() returns HTTP 200 for a valid item' do
    get item_iiif_media_sequence_path(@item, 'name-doesnt-matter')
    assert_response :ok
  end

  test 'iiif_media_sequence() returns HTTP 404 for an invalid item' do
    get item_iiif_media_sequence_path('bogus', 'name-doesnt-matter')
    assert_response :not_found
  end

  # iiif_range()

  test 'iiif_range() returns HTTP 200 for a valid item and subitem' do
    @item    = items(:compound_object_1002)
    @subitem = items(:compound_object_1002_page1)
    get item_iiif_range_path(@item, @subitem)
    assert_response :ok
  end

  test 'iiif_range() returns HTTP 404 for an invalid subitem' do
    @subitem = items(:compound_object_1002)
    @item    = items(:compound_object_1002_page1)
    get item_iiif_range_path(@item, @subitem)
    assert_response :not_found
  end

  # iiif_sequence()

  test 'iiif_sequence() returns HTTP 200 for a valid parent item and sequence name' do
    @item = items(:compound_object_1002)
    get item_iiif_sequence_path(@item, 'item')
    assert_response :ok
    get item_iiif_sequence_path(@item, 'page')
    assert_response :ok
  end

  test 'iiif_sequence() returns HTTP 404 for a valid parent item and invalid sequence name' do
    @item = items(:compound_object_1002)
    get item_iiif_sequence_path(@item, 'bogus')
    assert_response :not_found
  end

  test 'iiif_sequence() returns HTTP 404 for a child item and valid sequence name' do
    @item = items(:compound_object_1002_page1)
    get item_iiif_sequence_path(@item, 'item')
    assert_response :not_found
  end

  test 'iiif_sequence() returns HTTP 404 for an invalid item' do
    get item_iiif_sequence_path('bogus', 'item')
    assert_response :not_found
  end

  # index()

  test 'index() returns HTTP 404 for an invalid collection ID' do
    get collection_items_path('bogus')
    assert_response :not_found
  end

  test 'index() redirects to the show-collection page for unauthorized collections' do
    col = collections(:single_item_object)
    col.update!(restricted: true)
    get collection_items_path(col)
    assert_redirected_to collection_path(col)
  end

  test 'index() redirects to the Search Gateway when the q argument is not provided' do
    get items_path
    assert_response :moved_permanently
    assert_redirected_to ::Configuration.instance.metadata_gateway_url + '/items'
  end

  test 'index() returns HTTP 200 for Atom' do
    get items_path(q: 'query', format: :atom)
    assert_response :ok
  end

  test 'index() returns HTTP 200 for HTML' do
    get items_path(q: 'query')
    assert_response :ok
  end

  test 'index() returns HTTP 200 for JS' do
    get items_path(q: 'query', format: :js)
    assert_response :ok
  end

  test 'index() returns HTTP 200 for JSON' do
    get items_path(q: 'query', format: :json)
    assert_response :ok
  end

  test 'index() returns HTTP 200 for zip' do
    # TODO: write zip tests
  end

  # show() access control

  test 'show() allows access to non-expired restricted items by the correct NetID' do
    sign_in_as(users(:normal))
    @item.allowed_netids = [{ netid: 'normal',
                              expires: Time.now.to_i + 1.day.to_i }]
    @item.save!

    get item_path(@item)
    assert_response :ok
  end

  test 'show() allows access to non-expired restricted items by logged-in administrators' do
    sign_in_as(users(:admin))
    @item.allowed_netids = [{ netid: 'normal',
                              expires: Time.now.to_i + 1.day.to_i }]
    @item.save!

    get item_path(@item)
    assert_response :ok
  end

  test 'show() allows access to expired restricted items by logged-in administrators' do
    sign_in_as(users(:admin))
    @item.allowed_netids = [{ netid: 'normal',
                              expires: Time.now.to_i - 1.day.to_i }]
    @item.save!

    get item_path(@item)
    assert_response :ok
  end

  test 'show() forbids access to expired restricted items by the correct NetID' do
    sign_in_as(users(:normal))
    @item.allowed_netids = [{ netid: 'normal',
                              expires: Time.now.to_i - 1.day.to_i }]
    @item.save!

    get item_path(@item)
    assert_response :forbidden
  end

  test 'show() forbids access to restricted items with an incorrect NetID' do
    sign_in_as(users(:normal))
    @item.allowed_netids = [{ netid: 'user',
                              expires: Time.now.to_i + 1.day.to_i }]
    @item.save!

    get item_path(@item)
    assert_response :forbidden
  end

  test 'show() redirects to the sign-in route for restricted items for not-logged-in users' do
    @item.allowed_netids = [{ netid: 'user',
                              expires: Time.now.to_i + 1.day.to_i }]
    @item.save!

    get item_path(@item)
    assert_redirected_to signin_path
  end

  test 'show() restricts access to host group-restricted items' do
    # N.B.: Rails sets request.host to this pattern
    group = HostGroup.create!(key: 'test', name: 'Test',
                              pattern: 'www.example.com')
    @item.denied_host_groups << group
    @item.save!

    get item_path(@item)
    assert_response :forbidden
  end

  # show() with file- and directory-variants

  test 'show() does not allow access to file variants via non-XHR requests' do
    get item_path(@item)
    assert_response :found
    assert_redirected_to collection_tree_path(@item.collection,
                                              anchor: @item.repository_id)
  end

  test 'show() does not allow access to directory variants via non-XHR requests' do
    @item = items(:free_form_dir1)
    get item_path(@item)
    assert_response :found
    assert_redirected_to collection_tree_path(@item.collection,
                                              anchor: @item.repository_id)
  end

  test 'show() returns HTTP 400 for requests for file variants that are missing
  the tree-node-type argument' do
    get item_path(@item), xhr: true
    assert_response :bad_request
  end

  test 'show() returns HTTP 400 for requests for directory variants that are
  missing the tree-node-type argument' do
    @item = items(:free_form_dir1)
    get item_path(@item), xhr: true
    assert_response :bad_request
  end

  test 'show() allows access to file variants via XHR requests' do
    get item_path(@item, 'tree-node-type': 'file_node'), xhr: true
    assert_response :ok
  end

  test 'show() allows access to directory variants via XHR requests' do
    @item = items(:free_form_dir1)
    get item_path(@item, 'tree-node-type': 'directory_node'), xhr: true
    assert_response :ok
  end

  # show() with non-free-form variants

  test 'show() returns HTTP 200 for compound objects' do
    @item = items(:compound_object_1002)
    get item_path(@item)
    assert_response :ok
  end

  test 'show() returns HTTP 200 for single-item objects' do
    @item = items(:compound_object_1001)
    get item_path(@item)
    assert_response :ok
  end

  # show() output format

  test 'show() Atom returns HTTP 200' do
    get item_path(@item, format: :atom)
    assert_response :success
  end

  test 'show() JSON returns HTTP 200' do
    get item_path(@item, format: :json)
    assert_response :success
  end

  test 'show() PDF redirects to download URL for compound objects' do
    @item = items(:compound_object_1002)
    get item_path(@item, format: :pdf)
    assert_response :found
  end

  test 'show() PDF redirects to show-item page for non-compound objects' do
    get item_path(@item, format: :pdf)
    assert_redirected_to item_path(@item)
  end

  test 'show() zip' do
    # TODO: write all these zip format tests
  end

end

