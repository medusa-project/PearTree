iiif_layer_for(@item, @layer_name).each do |k, v|
  json.set! k, v
end