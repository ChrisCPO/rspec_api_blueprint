require "rspec_api_blueprint/version"

unless "".respond_to?(:indent)
  class String
    def indent(count, char = ' ')
      gsub(/([^\n]*)(\n|$)/) do |match|
        last_iteration = ($1 == "" && $2 == "")
        line = ""
        line << (char * count) unless last_iteration
        line << $1
        line << $2
        line
      end
    end
  end
end

RSpec.configure do |config|
  config.before(:all, type: :request) do
    api_docs_folder_path = File.join(Rails.root, '/api_docs/')
    Dir.mkdir(api_docs_folder_path) unless Dir.exists?(api_docs_folder_path)

    Dir.glob(File.join(api_docs_folder_path, '*')).each do |f|
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

      File.open(File.join(Rails.root, "/api_docs/#{file_name}.txt"), 'a') do |f|
        # Resource & Action
        f.write "# #{action}\n\n"

        # Request
        request_body = request.body.read
        authorization_header = request.headers['Authorization']

        if request_body.present? || authorization_header.present?
          f.write "+ Request #{request.content_type}\n\n"

          # Request Headers
          if authorization_header.present?
            f.write "+ Headers\n\n".indent(4)
            f.write "Authorization: #{authorization_header}\n\n".indent(12)
          end

          # Request Body
          if request_body.present?
            f.write "+ Body\n\n".indent(4) if authorization_header
            f.write "#{JSON.pretty_generate(JSON.parse(request_body))}\n\n".indent(authorization_header ? 12 : 8)
          end
        end

        # Response
        f.write "+ Response #{response.status} #{response.content_type}\n\n"

        if response.body.present?
          f.write "#{JSON.pretty_generate(JSON.parse(response.body))}\n\n".indent(8)
        end
      end unless response.status == 401 || response.status == 403 || response.status == 301
    end
  end
end
