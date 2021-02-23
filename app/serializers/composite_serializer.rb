class CompositeSerializer
  include JSONAPI::Serializer
  set_key_transform :camel_lower
  attributes :name,
             :description,
             :image,
             :type,
             :regular_price_cents,
             :sale_price_cents,
             :inventory_amount,
             :slug

  has_many :categories
  has_many :components
end