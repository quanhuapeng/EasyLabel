Pod::Spec.new do |s|
  s.name             = 'EasyLabel'
  s.version          = '1.0.0'
  s.summary          = '能够异步绘制的 UILabel'
 
  s.description      = <<-DESC
    能够异步绘制的 UILabel。
                       DESC
 
  s.swift_version    = '5.0'
  s.homepage         = 'https://github.com/quanhuapeng/EasyLabel'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'pengquanhua' => 'im.pengqh@gmail.com' }
  s.source           = { :git => 'https://github.com/quanhuapeng/EasyLabel.git', :tag => s.version }
 
  s.ios.deployment_target = '11.0'
  s.source_files = 'EasyLabel/*.{swift}', 'EasyLabel/YYLayer/*.{swift}'
  s.static_framework = true
end
