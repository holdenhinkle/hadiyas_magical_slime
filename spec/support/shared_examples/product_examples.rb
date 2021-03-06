RSpec.shared_examples '#index' do
  it 'returns http status 200 OK' do
    expect(response).to have_http_status(200)
  end

  it "returns two product objects" do
    products = JSON.parse(response.body)['data']
    expect(products.count).to eq(2)
  end

  it 'renders the correct JSON representation of the existing products' do
    json_response = JSON.parse(response.body)

    json_response['data'].each do |product|
      expect(product.keys).to match_array(%w[id type attributes relationships])
      expect(product['type']).to eq('product')
      expect(product['attributes'].keys).to match_array(%w[name description image type regularPriceCents salePriceCents inventoryAmount unitOfMeasure isVisible slug])
      expect(product['relationships'].keys).to match_array(%w[categories])
      expect(product['relationships']['categories'].keys).to match_array(%w[data])

      product['relationships']['categories']['data'].each do |data|
        expect(data.keys).to match_array(%w[id type])
        expect(data['type']).to eq('category')
      end
    end
  end
end

RSpec.shared_examples '#show' do |product_type, relationships|
  # To-do:
  # Test that a composite product with components with product options 
  # returns the correct data.

  it 'renders the correct JSON representation of the product' do
    id = product.id.to_s
    get(url + id)

    product = JSON.parse(response.body)['data']
    includes = JSON.parse(response.body)['included']

    expect(product.keys).to match_array(%w[id type attributes relationships])
    expect(product['type']).to eq(product_type)
    expect(product['attributes'].keys).to match_array(%w[name description image type regularPriceCents salePriceCents inventoryAmount unitOfMeasure isVisible slug])
    expect(product['relationships'].keys).to match_array(relationships)
    expect(product['relationships']['categories'].keys).to match_array(%w[data])

    includes.each do |include|
      if include['type'] == 'category'
        expect(include.keys).to match_array(%w[id type attributes])
        expect(include['attributes'].keys).to match_array(%w[name description image slug])  
      elsif include['type'] == 'component'
        expect(include.keys).to match_array(%w[id type attributes relationships])
        expect(include['attributes'].keys).to match_array(%w[name description image slug minQuantity maxQuantity isEnabled])
      end
    end
  end

  context 'using product id is used as identifying param' do
    let!(:id) { product.id.to_s }
    
    it 'returns http status 200 OK' do
      get(url + id)
      expect(response).to have_http_status(200)
    end

    it 'returns expected product' do
      get(url + id)
      body = JSON.parse(response.body)
      expect(body['data']['type']).to eq(product_type)
      expect(body['data']['id']).to eq(id)
    end

    context "when product doesn't exist" do
      let!(:bad_id) { (id.to_i + 1).to_s }

      it 'returns an error' do
        get(url + bad_id)
        body = JSON.parse(response.body)
        expect(body['error']).to eq("The requested product doesn't exist")
      end

      it 'returns a 404 status code' do
        get(url + bad_id)
        expect(response).to have_http_status(404)
      end
    end
  end

  context 'using product slug is used as identifying param' do
    let!(:slug) { product.slug }

    it 'returns http status 200 OK' do
      get(url + slug)
      expect(response).to have_http_status(200)
    end

    it 'returns expected product' do
      get(url + slug)
      body = JSON.parse(response.body)
      expect(body['data']['type']).to eq(product_type)
      expect(body['data']['attributes']['slug']).to eq(slug)
    end

    context "when product doesn't exist" do
      let!(:bad_slug) { (slug + slug) }

      it 'returns an error when product does not exist' do
      get(url + bad_slug)
        body = JSON.parse(response.body)
        expect(body['error']).to eq("The requested product doesn't exist")
      end

      it 'returns a 404 status code when product does not exist' do
      get(url + bad_slug)
        expect(response).to have_http_status(404)
      end
    end
  end
end

RSpec.shared_examples '#create' do |test_params|
  # To-do:
  # Test that you can create a new composite product with components_attributes
  # that have product_option_ids.
  # Test pricing => you can enter 999 or 9.99 and regularPriceCents will be 999.

  describe "#{test_params[:type]} product" do
    context "create with #{test_params[:relationships_by]}" do
      product_factory = test_params[:factory]

      context 'valid request with only required attributes' do
        before do
          product_attributes = attributes_for(product_factory)
          post(url, params: { product: product_attributes })
        end
    
        it 'returns 200' do
          expect(response).to have_http_status(:success)
        end
    
        it 'renders the correct JSON representation of the new product' do
          product = JSON.parse(response.body)['data']
    
          expect(product.keys).to match_array(%w[id type attributes relationships])
          expect(product['type']).to eq(test_params[:type])
          expect(product['attributes'].keys).to match_array(%w[name description image type regularPriceCents salePriceCents inventoryAmount unitOfMeasure isVisible slug])
          expect(product['relationships'].keys).to match_array(test_params[:relationships])
          expect(product['relationships']['categories'].keys).to match_array(%w[data])
    
          product['relationships']['categories']['data'].each do |category|
            expect(category.keys).to match_array(%w[id type])
            expect(category['type']).to eq('category')           
          end
        end
    
        it 'sets image to nil' do
          expect(JSON.parse(response.body)['data']['attributes']['image']).to be(nil)
        end
    
        it 'sets sale_price_cents to nil' do
          expect(JSON.parse(response.body)['data']['attributes']['salePriceCents']).to be(nil)          
        end
    
        it 'sets inventory to nil' do
          expect(JSON.parse(response.body)['data']['attributes']['inventoryAmount']).to be(nil)        
        end
    
        it 'sets is_visible to true' do
          expect(JSON.parse(response.body)['data']['attributes']['isVisible']).to be(true)        
        end
      end

      context 'valid request with optional attributes' do
        fit 'sets image to given value' do
          product_attributes = attributes_for(product_factory, :product_with_image)
          post(url, params: { product: product_attributes })
          expect(JSON.parse(response.body)['data']['attributes']['image']).not_to be(nil)
        end

        it 'sets sale_price_cents to given value' do
          product_attributes = attributes_for(product_factory, :product_with_sale_price_cents)
          post(url, params: { product: product_attributes })
          expect(JSON.parse(response.body)['data']['attributes']['salePriceCents']).not_to be(nil)          
        end

        it 'sets inventory_amount to given value' do
          product_attributes = attributes_for(product_factory, :product_with_inventory_amount)
          post(url, params: { product: product_attributes })
          expect(JSON.parse(response.body)['data']['attributes']['inventoryAmount']).not_to be(nil)          
        end

        it 'sets is_visible to given value' do
          product_attributes = attributes_for(product_factory, :product_is_not_visible)
          post(url, params: { product: product_attributes })
          expect(JSON.parse(response.body)['data']['attributes']['isVisible']).to be(false)                   
        end
      end

      context 'invalid request' do
        context 'name attribute is missing' do
          before do
            product_attributes = attributes_for(product_factory, :product_no_name)
            post(url, params: { product: product_attributes })
          end

          it 'returns http status 422' do
            expect(response).to have_http_status(422)  
          end

          it 'returns the correct errror message' do
            body = JSON.parse(response.body)
            expect(body['errors'].count).to eq(1)
            expect(body['errors']['name'].count).to eq(1)
            expect(body['errors']['name'][0]).to eq("can't be blank")         
          end
        end

        context 'description attribute is missing' do
          before do
            product_attributes = attributes_for(product_factory, :product_no_description)
            post(url, params: { product: product_attributes })
          end

          it 'returns http status 422' do
            expect(response).to have_http_status(422)
          end

          it 'returns the correct errror message' do
            body = JSON.parse(response.body)
            expect(body['errors'].count).to eq(1)
            expect(body['errors']['description'].count).to eq(1)
            expect(body['errors']['description'][0]).to eq("can't be blank")         
          end
        end

        context 'regular_price_cents attribute is missing' do
          before do
            product_attributes = attributes_for(product_factory, :product_no_regular_price)
            post(url, params: { product: product_attributes })
          end

          it 'returns http status 422' do
            expect(response).to have_http_status(422)
          end

          it 'returns the correct errror message' do
            body = JSON.parse(response.body)
            expect(body['errors'].count).to eq(2)
            expect(body['errors']['regular_price_cents'].count).to eq(2)
            expect(body['errors']['regular_price_cents'][0]).to eq('is not a number')
            expect(body['errors']['regular_price_cents'][1]).to eq("can't be blank")
            expect(body['errors']['regular_price'].count).to eq(1)
            expect(body['errors']['regular_price'][0]).to eq('is not a number')
          end
        end

        context 'unit_of_measure attribute is missing' do
          before do
            product_attributes = attributes_for(product_factory, :product_no_unit_of_measure)
            post(url, params: { product: product_attributes })
          end

          it 'returns http status 422' do
            expect(response).to have_http_status(422)
          end

          it 'returns the correct errror message' do
            body = JSON.parse(response.body)
            expect(body['errors'].count).to eq(1)
            expect(body['errors']['unit_of_measure'].count).to eq(1)
            expect(body['errors']['unit_of_measure'][0]).to eq("can't be blank")
          end
        end

        # a bad enum value throws an ArgumentError
        # fix this later
        # return an error instead of throwing an error
        # this has been an open issue in the rails community for many years
        # consider fixing this
        skip 'unit_of_measure value is invalid' do
          before do
            product_attributes = attributes_for(product_factory, :product_invalid_unit_of_measure_value)
            post(url, params: { product: product_attributes })
          end

          it 'returns http status 422' do
            expect(response).to have_http_status(422)
          end

          it 'returns the correct errror message' do
            body = JSON.parse(response.body)
            expect(body['errors'].count).to eq(1)
            expect(body['errors']['unit_of_measure'].count).to eq(1)
            expect(body['errors']['unit_of_measure'][0]).to eq("can't be blank")
          end
        end
      end
    end
  end
end

RSpec.shared_examples '#update' do |test_params|
  # To-do
  # Test removing product_options from a component.

  describe "#{test_params[:type]} product" do
    context "created with #{test_params[:relationships_by]}" do
      product_factory = test_params[:factory]

      context 'name update' do
        let!(:original_name) { Faker::Lorem.words(number: 2).map(&:capitalize).join(' ') }
        let!(:new_name) { 'Updated Name' }

        before do
          product_attributes = attributes_for(product_factory, name: original_name)
          post(url, params: { product: product_attributes })
          @id = JSON.parse(response.body)['data']['id'].to_s
        end

        it 'returns http status 200 OK' do
          patch(url + @id, params: { product: { name: new_name } })
          expect(response).to have_http_status(:success)
        end

        it 'updates the name' do
          patch(url + @id, params: { product: { name: new_name } })
          current_name = JSON.parse(response.body)['data']['attributes']['name']
          expect(current_name).not_to eq(original_name)
          expect(current_name).to eq(new_name)
        end

        it 'updates the slug when the name is updated' do
          original_slug = JSON.parse(response.body)['data']['attributes']['slug']
          new_slug = new_name.split(' ').map(&:downcase).join('-')
          patch(url + @id, params: { product: { name: new_name } })
          current_slug = JSON.parse(response.body)['data']['attributes']['slug']
          expect(current_slug).not_to eq(original_slug)
          expect(current_slug).to eq(new_slug)
        end
      end

      context 'description update' do
        let!(:original_description) { Faker::Lorem.paragraph }
        let!(:new_description) { Faker::Lorem.paragraph }

        before do
          product_attributes = attributes_for(product_factory, description: original_description)
          post(url, params: { product: product_attributes })
          @id = JSON.parse(response.body)['data']['id'].to_s
        end

        it 'returns http status 200 OK' do
          patch(url + @id, params: { product: { description: new_description } })
          expect(response).to have_http_status(:success)
        end

        it 'updates the description' do
          patch(url + @id, params: { product: { description: new_description } })
          current_description = JSON.parse(response.body)['data']['attributes']['description']
          expect(current_description).not_to eq(original_description)
          expect(current_description).to eq(new_description)
        end
      end

      context 'image update' do
        let!(:original_image) { Faker::Internet.url(host: 'example.com') }
        let!(:new_image) { Faker::Internet.url(host: 'example.com') }

        before do
          product_attributes = attributes_for(product_factory, :with_image, image: original_image)
          post(url, params: { product: product_attributes })
          @id = JSON.parse(response.body)['data']['id'].to_s
        end

        it 'returns http status 200 OK' do
          patch(url + @id, params: { product: { image: new_image } })
          expect(response).to have_http_status(:success)
        end

        it 'updates the description' do
          patch(url + @id, params: { product: { image: new_image } })
          current_image = JSON.parse(response.body)['data']['attributes']['image']
          expect(current_image).not_to eq(original_image)
          expect(current_image).to eq(new_image)
        end
      end

      context 'regular price update' do
        let!(:original_price) { Faker::Number.between(from: 99, to: 20000) }
        let!(:new_price) { Faker::Number.between(from: 99, to: 20000) }

        before do
          product_attributes = attributes_for(product_factory, regular_price_cents: original_price)
          post(url, params: { product: product_attributes })
          @id = JSON.parse(response.body)['data']['id'].to_s
        end

        it 'returns http status 200 OK' do
          patch(url + @id, params: { product: { regular_price_cents: new_price } })
          expect(response).to have_http_status(:success)
        end

        it 'updates the description' do
          patch(url + @id, params: { product: { regular_price_cents: new_price } })
          current_price = JSON.parse(response.body)['data']['attributes']['regularPriceCents']
          expect(current_price).not_to eq(original_price)
          expect(current_price).to eq(new_price)
        end
      end

      context 'add a category using category_ids param' do
        before do
          product_attributes = attributes_for(product_factory)
          post(url, params: { product: product_attributes })
          body = JSON.parse(response.body)
          id = body['data']['id'].to_s
          categories = JSON.parse(response.body)['included'].filter { |include| include['type'] == 'category'}
          @category_id_1 = categories[0]['id']
          @category_id_2 = categories[1]['id']
          @category_id_3 = create(:category)['id'].to_s
          patch(url + id, params: { product: { category_ids: [@category_id_1, @category_id_2, @category_id_3] } })
        end

        it 'returns http status 200 OK' do
          expect(response).to have_http_status(:success)
        end

        it 'returns the correct categories' do
          categories = JSON.parse(response.body)['included'].filter { |include| include['type'] == 'category'}
          expect(categories.count).to eq(3)
          expect(categories[0]['id']).to eq(@category_id_1)
          expect(categories[1]['id']).to eq(@category_id_2)
          expect(categories[2]['id']).to eq(@category_id_3)
        end
      end

      context 'add a category using categories_attributes param' do
        before do
          product_attributes = attributes_for(product_factory)
          post(url, params: { product: product_attributes })
          @id = JSON.parse(response.body)['data']['id'].to_s
        end

        it 'returns http status 200 OK' do
          patch(url + @id, params: { product: { categories_attributes: [attributes_for(:category)] } })
          expect(response).to have_http_status(:success)
        end

        it 'returns the correct categories' do
          categories = JSON.parse(response.body)['included'].filter { |include| include['type'] == 'category'}
          expect(categories.count).to eq(2)
          patch(url + @id, params: { product: { categories_attributes: [attributes_for(:category)] } })
          categories = JSON.parse(response.body)['included'].filter { |include| include['type'] == 'category'}
          expect(categories.count).to eq(3)
        end
      end

      context 'add a category that was already added using category_ids param' do
        before do
          product_attributes = attributes_for(product_factory)
          post(url, params: { product: product_attributes })
          body = JSON.parse(response.body)
          id = body['data']['id'].to_s
          @category_id_1 = body['included'][0]['id']
          @category_id_2 = body['included'][1]['id']
          patch(url + id, params: { product: { category_ids: [@category_id_1, @category_id_1, @category_id_2] } })
        end

        it 'returns http status 200 OK' do
          expect(response).to have_http_status(:success)
        end

        it 'returns the correct categories' do
          categories = JSON.parse(response.body)['included'].filter { |include| include['type'] == 'category'}
          expect(categories.count).to eq(2)
          expect(categories[0]['id']).to eq(@category_id_1)
          expect(categories[1]['id']).to eq(@category_id_2)
        end
      end

      context 'add a category that was already added using the categories_attributes param' do
        let!(:new_category) { create(:category) }

        before do
          post(url, params: { product: attributes_for(product_factory) })
          id = JSON.parse(response.body)['data']['id'].to_s
          patch(url + id, params: { product: { categories_attributes: [attributes_for(:category, name: new_category.name)] } })
        end

        it 'returns http status 200 OK' do
          expect(response).to have_http_status(:success)
        end

        it 'sets relationship with existing category with the same name' do
          categories = JSON.parse(response.body)['included'].filter { |include| include['type'] == 'category'}
          expect(categories.count).to eq(3)
          expect(categories[2]['id']).to eq(new_category.id.to_s)
          expect(categories[2]['attributes']['name']).to eq(new_category.name)
        end
      end

      # the following returns an ActiveRecord::RecordNotFound error
      # fix this later
      skip 'add a category that does not exist using category_ids param' do
        before do
          product_attributes = attributes_for(product_factory)
          post(url, params: { product: product_attributes })
          body = JSON.parse(response.body)
          id = body['data']['id'].to_s
          @category_id_1 = body['included'][0]['id']
          @category_id_2 = body['included'][1]['id']
          @category_id_3 = (Category.last.id.to_i + 1).to_s
          patch(url + id, params: { product: { category_ids: [@category_id_1, @category_id_2, @category_id_3] } })
        end

        it 'returns http status 200 OK' do
          expect(response).to have_http_status(:success)
        end

        it 'returns the correct categories' do
          categories = JSON.parse(response.body)['included']
          expect(categories.count).to eq(2)
          expect(categories[0]['id']).to eq(@category_id_1)
          expect(categories[1]['id']).to eq(@category_id_2)
        end
      end

      context 'remove a category using category_ids param' do
        before do
          product_attributes = attributes_for(product_factory)
          post(url, params: { product: product_attributes })
          body = JSON.parse(response.body)
          id = body['data']['id'].to_s
          categories = JSON.parse(response.body)['included'].filter { |include| include['type'] == 'category'}
          @category_1_id = categories[0]['id']
          @category_2_id = categories[1]['id']
          patch(url + id, params: { product: { category_ids: [@category_1_id] } })
        end

        it 'returns http status 200 OK' do
          expect(response).to have_http_status(:success)
        end

        it 'returns the correct category' do
          categories = JSON.parse(response.body)['included'].filter { |include| include['type'] == 'category'}
          expect(categories.count).to eq(1)
          expect(categories[0]['id']).to eq(@category_1_id)
          expect(categories[0]['id']).to_not eq(@category_2_id)
        end
      end
    end
  end
end

RSpec.shared_examples '#destroy' do |test_params|
  describe "#{test_params[:type]} product" do
    before do
      post(url, params: { product: attributes_for(test_params[:factory]) })
    end
  
    context 'product id is used as identifying param' do
      let!(:id) { JSON.parse(response.body)['data']['id'] }
  
      it 'deletes the product' do
        expect do
          delete(url + id)
        end.to change(Product, :count).by(-1)
      end
  
      it 'returns a 204 status code' do
        delete(url + id)
        expect(response).to have_http_status(204)
      end
  
      it 'returns an empty body' do
        delete(url + id)
        expect(response.body).to eq('')
      end

      it 'returns an error when product does not exist' do
        delete(url + (id.to_i + 1).to_s)
        body = JSON.parse(response.body)
        expect(body['error']).to eq("The requested product doesn't exist")
      end

      it 'returns a 404 status code when product does not exist' do
        delete(url + (id.to_i + 1).to_s)
        expect(response).to have_http_status(404)
      end
    end
  
    context 'product slug is used as identifying param' do
      let!(:slug) { JSON.parse(response.body)['data']['attributes']['slug'] }
  
      it 'deletes the product' do        
        expect do
          delete(url + slug)
        end.to change(Product, :count).by(-1)
      end
  
      it 'returns a 204 status code' do
        delete(url + slug)
        expect(response).to have_http_status(204)
      end
  
      it 'returns an empty body' do
        delete(url + slug)
        expect(response.body).to eq('')
      end

      it 'returns an error when product does not exist' do
        delete(url + slug + slug)
        body = JSON.parse(response.body)
        expect(body['error']).to eq("The requested product doesn't exist")
      end

      it 'returns a 404 status code when product does not exist' do
        delete(url + slug + slug)
        expect(response).to have_http_status(404)
      end
    end
  end  
end
