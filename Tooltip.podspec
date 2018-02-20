Pod::Spec.new do |s|
  s.name             = 'Tooltip'
  s.version          = '0.0.1'
  s.summary          = 'Tooltip'
  s.homepage         = 'https://github.com/efremidze/Tooltip'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'efremidze' => 'efremidzel@hotmail.com' }
  s.source           = { :git => 'https://github.com/efremidze/Tooltip.git', :tag => s.version.to_s }
  s.ios.deployment_target = '9.0'
  s.source_files = 'Sources/*.swift'
end
