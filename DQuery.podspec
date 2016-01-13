Pod::Spec.new do |s|
  s.name         = "DQuery"
  s.version      = "0.1.1"
  s.summary      = "iOS data framework based on Core Data"

  s.description  = <<-DESC
  DQuery is a framework for querying/manipulating persistent data in iOS. It based on and fully compatible with Core Data. DQuery uses simple DSLs to do queries, and supports asynchronous fetches/writes out of the box.
                   DESC

  s.homepage     = "https://github.com/codescv/DQuery"
  s.license      = "Apache License, Version 2.0"
  s.author             = { "Chi Zhang" => "chi.zhang@codescv.com" }

  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/codescv/DQuery.git", :tag => "0.1.1" }

  s.source_files  = "DQuery"

end
