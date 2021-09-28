
Pod::Spec.new do |s|
  s.name             = "GoldDigger"
  s.version          = "0.7.0"
  s.summary          = "Simple ORM"
  s.description      = "Simple ORM for Objective-C"
  s.homepage         = "https://github.com/CopyIsRight/GoldDigger.git"
  s.license          = 'MIT'
  s.author           = { "Pietro Caselani" => "pc1992@gmail.com", "Felipe Lobo" => "frlwolf@gmail.com", "Bruno da Luz" => "brunolabx@gmail.com" }
  s.source           = { :git => "https://github.com/CopyIsRight/GoldDigger.git", :tag => s.version.to_s }
  s.platform         = :ios, '8.0'
  s.requires_arc     = true
  s.source_files     = 'Pod/*.{h,m}'

  s.dependency    'SQLAid', '0.2.0'

  s.subspec 'Parser' do |psr|
    psr.source_files   = 'Pod/Parser/*.{h,m}'

    psr.dependency   'ObjectiveSugar', '1.1.0'
  end

  s.subspec 'Mapper' do |mpr|
    mpr.source_files    = 'Pod/Mapper/*.{h,m}'

    mpr.dependency    'GoldDigger/Parser'
  end

  s.subspec 'ActiveRecorder' do |adr|
    adr.source_files    = 'Pod/ActiveRecorder/*.{h,m}'

    adr.dependency    'GoldDigger/Mapper'
  end

end
