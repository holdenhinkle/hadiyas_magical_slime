class ComponentSerializer
  include JSONAPI::Serializer
  set_key_transform :camel_lower
  attributes :name, :description, :image, :slug, :min_quantity, :max_quantity, :is_enabled
end