#
# Be sure to run `pod lib lint GoldDigger.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "GoldDigger"
  s.version          = "0.2.1"
  s.summary          = "Simple ORM"
  s.description      = "Simple ORM for Objective-C"
  s.homepage         = "https://github.com/CopyIsRight/GoldDigger.git"
  s.license          = 'MIT'
  s.author           = { "Pietro Caselani" => "pc1992@gmail.com", "Felipe Lobo" => "frlwolf@gmail.com" }
  s.source           = { :git => "https://github.com/CopyIsRight/GoldDigger.git", :tag => s.version.to_s }
  s.platform         = :ios, '7.0'
  s.requires_arc     = true
  s.source_files     = 'Pod/Classes/**/*'

  s.dependency 'SQLAid', '~> 0.1'
  s.dependency 'ObjectiveSugar', '1.1.0'
end
