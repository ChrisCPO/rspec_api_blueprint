require "rspec_api_blueprint/version"

RSpec.configure do |config|
  config.before(:suite) do
    Dir.glob(File.join(Rails.root, '/docs/', '*')).each do |f|
      File.delete(f)
    end
  end

  config.after(:each, type: :request) do
    if response
      example_group = example.metadata[:example_group]
      example_groups = []

      while example_group
        example_groups << example_group
        example_group = example_group[:example_group]
      end

      action = example_groups[-2][:description_args].first if example_groups[-2]
      example_groups[-1][:description_args].first.match(/(\w+)\sRequests/)
      file_name = $1.underscore

      File.open(File.join(Rails.root, "/docs/#{file_name}.txt"), 'a') do |f|
        # Resource & Action
        f.write "# #{action}\n\n"

        # Request
        request_body = request.body.read
        authorization_header = request.headers['Authorization']

        if request_body.present? || authorization_header.present?
          f.write "+ Request (application/json)\n\n"

          # Request Headers
          if authorization_header
            f.write "+ Headers\n\n".indent(4)
            f.write "Authorization: #{authorization_header}\n\n".indent(8)
          end

          # Request Body
          if request_body.present?
            f.write "+ Body\n\n".indent(4)
            f.write "#{JSON.pretty_generate(JSON.parse(request_body))}\n\n".indent(8)
          end

        end

        # Response
        f.write "+ Response #{response.status} (application/json)\n\n"

        if response.body.present?
          f.write "#{JSON.pretty_generate(JSON.parse(response.body))}\n\n".indent(8)
        end
      end unless response.status == 401 || response.status == 403 || response.status == 301
    end
  end
end
