set -x
rm -rf build/
mkdir -p build/logstash-upgradeable-pack/logstash/
gem build logstash-input-secret.gemspec
mv logstash-input-secret*.gem build/logstash-upgradeable-pack/logstash/
wget https://rubygems.org/downloads/rubyzip-1.2.1.gem
mkdir build/logstash-upgradeable-pack/logstash/dependencies
mv rubyzip*.gem build/logstash-upgradeable-pack/logstash/dependencies

cd build/
zip -r logstash-upgradeable-pack.zip logstash-upgradeable-pack
cp *.zip ../
cd ..
