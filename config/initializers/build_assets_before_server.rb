if Rails.env.development? && defined?(Rails::Server)
  package_json_path = Rails.root.join("package.json")

  if File.exist?(package_json_path)
    puts "Building JS..."
    system("yarn build")

    puts "Building CSS..."
    system("yarn build:css")
  end
end
