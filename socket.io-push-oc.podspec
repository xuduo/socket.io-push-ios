Pod::Spec.new do |s|
  s.name         = 'socket.io-push-oc'
  s.version      = '0.0.5'
  s.summary      = 'socket.io-push-oc'
  s.homepage     = 'https://github.com/xuduo/socket.io-push-ios'
  s.license      = {
      :type => 'GNU General Public License v2.0',
      :file => "LICENSE"
  }
  s.dependency 'SocketRocket'
  s.dependency 'SAMKeychain' 
  s.author       = { 'author' => 'xuudoo@gmail.com' }
  s.platform     = :ios, '7.0'
  s.requires_arc = true
  s.source_files = 'source-oc/*'
  s.source       = { :git => 'https://github.com/xuduo/socket.io-push-ios' }
end
