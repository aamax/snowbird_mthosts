json.array!(@hosts) do |host|
  json.id           host[:id]
  json.name         host[:name]
end