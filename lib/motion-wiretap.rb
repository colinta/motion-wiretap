unless defined?(Motion::Project::Config)
  raise "The motion-wiretap gem must be required within a RubyMotion project Rakefile."
end


Motion::Project::App.setup do |app|
  # scans app.files until it finds app/ (the default)
  # if found, it inserts just before those files, otherwise it will insert to
  # the end of the list
  insert_point = app.files.find_index { |file| file =~ /^(?:\.\/)?app\// } || 0

  app.files.insert(insert_point, File.join(File.dirname(__FILE__), "motion-wiretap/version.rb"))
  app.files.insert(insert_point, *Dir.glob(File.join(File.dirname(__FILE__), "motion-wiretap/#{app.template.to_s}/*.rb")))
  app.files.insert(insert_point, *Dir.glob(File.join(File.dirname(__FILE__), "motion-wiretap/all/*.rb")))

  wiretap = File.join(File.dirname(__FILE__), "motion-wiretap/all/wiretap.rb")
  signal = File.join(File.dirname(__FILE__), "motion-wiretap/all/signal.rb")
  app.files_dependencies signal => [wiretap]
end
