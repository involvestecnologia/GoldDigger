
Pod::Spec.new do |s|
  s.name             = "GoldDigger"
  s.version          = "0.7.8"
  s.summary          = "Simple ORM"
  s.description      = "Simple ORM for Objective-C"
  s.homepage         = "https://github.com/CopyIsRight/GoldDigger.git"
  s.license          = 'MIT'
  s.author           = { "Pietro Caselani" => "pc1992@gmail.com", "Felipe Lobo" => "frlwolf@gmail.com", "Bruno da Luz" => "brunolabx@gmail.com" }
  s.source           = { :git => "https://github.com/CopyIsRight/GoldDigger.git", :tag => s.version.to_s }
  s.platform         = :ios, '10.0'

  s.requires_arc     = true
  
  s.subspec 'Core' do |core|
    core.source_files   = 'Pod/Core/*.{h,m}'

    core.dependency   'ObjectiveSugar', '1.1.0'
  end

  s.subspec 'SQL' do |sql|
    sql.source_files    = 'Pod/SQL/*.{h,m}'

    sql.dependency    'GoldDigger/Core'
    sql.dependency    'SQLAids', '0.2.1'
  end

end
