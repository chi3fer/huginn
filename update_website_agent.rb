file_path = "signal-sequence-mvp/infra/huginn-fork/app/models/agents/website_agent.rb"
content = File.read(file_path)

content.sub!(/when 'css', 'xpath', 'value', 'repeat', 'hidden', 'raw', 'single_array'/, "when 'css', 'xpath', 'value', 'repeat', 'hidden', 'raw', 'single_array', 'absolute'")

content.sub!(/def handle_data\(body, url, existing_payload\).*?output =\n\s*case extraction_type\n\s*when 'json'\n\s*extract_json\(doc\)\n\s*when 'text'\n\s*extract_text\(doc\)\n\s*else\n\s*extract_xml\(doc\)\n\s*end/m) do |match|
  match.gsub('extract_json(doc)', 'extract_json(doc, url)')
       .gsub('extract_text(doc)', 'extract_text(doc, url)')
       .gsub('extract_xml(doc)', 'extract_xml(doc, url)')
end

content.sub!(/def extract_json\(doc\)/, 'def extract_json(doc, url = nil)')
content.sub!(/def extract_text\(doc\)/, 'def extract_text(doc, url = nil)')
content.sub!(/def extract_xml\(doc\)/, 'def extract_xml(doc, url = nil)')

# Add resolve_url method
resolve_url_method = <<~RUBY

    def resolve_url(value, extraction_details, url)
      return value unless boolify(extraction_details['absolute']) && url.present?
      case value
      when String
        begin
          URI.join(url, value).to_s
        rescue URI::Error
          value
        end
      when Array
        value.map { |v| resolve_url(v, extraction_details, url) }
      else
        value
      end
    end

    def extract_json(doc, url = nil)
RUBY

content.sub!(/    def extract_json\(doc, url = nil\)\n/m, resolve_url_method)

# Replace extract_json inner loop
content.sub!(/Utils\.values_at\(doc, extraction_details\['path'\]\)\.each \{ \|value\|\n\s*values << value\n\s*\}/m) do
<<~RUBY.chomp
Utils.values_at(doc, extraction_details['path']).each { |value|
          values << resolve_url(value, extraction_details, url)
        }
RUBY
end

# Replace extract_text inner loop
content.sub!(/doc\.scan\(regexp\) \{\n\s*values << Regexp\.last_match\[index\]\n\s*\}/m) do
<<~RUBY.chomp
doc.scan(regexp) {
          values << resolve_url(Regexp.last_match[index], extraction_details, url)
        }
RUBY
end

# Replace extract_xml inner loop
content.sub!(/node_values = nodes\.map \{ \|node\|\n\s*jsonify\.call\(node\.xpath\(expr\)\)\n\s*\}/m) do
<<~RUBY.chomp
node_values = nodes.map { |node|
            resolve_url(jsonify.call(node.xpath(expr)), extraction_details, url)
          }
RUBY
end

File.write(file_path, content)
