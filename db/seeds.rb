# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

23.times do |i|
  Lock.create!(namespace: "testnamespace", resource: "testresource_#{i}", owner: "testowner", expires: Time.now + rand(36000))
end
