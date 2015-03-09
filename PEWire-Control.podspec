Pod::Spec.new do |s|
  s.name         = "PEWire-Control"
  s.version      = "1.0.0"
  s.license      = "MIT"
  s.summary      = "An iOS library for the easy stubbing of HTTP responses using simple XML files."
  s.author       = { "Paul Evans" => "evansp2@gmail.com" }
  s.homepage     = "https://github.com/evanspa/#{s.name}"
  s.source       = { :git => "https://github.com/evanspa/#{s.name}.git", :tag => "#{s.name}-v#{s.version}" }
  s.platform     = :ios, '8.1'
  s.source_files = '**/*.{h,m}'
  s.public_header_files = '**/*.h'
  s.exclude_files = "**/*Tests/*.*"
  s.requires_arc = true
  s.dependency 'PEObjc-Commons', '~> 1.0.1'
  s.dependency 'PEXML-Utils', '~> 1.0.1'
  s.dependency 'OHHTTPStubs', '~> 3.1.10'
  s.xcconfig     = { 'HEADER_SEARCH_PATHS' => '"$(SDKROOT)/usr/include/libxml2"' }
end
