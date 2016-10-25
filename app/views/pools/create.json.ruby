if @persisted && !(@errors && !@errors.empty?)
  # success response
  {name: @pool.name, resource: @pool.resource,
    active: @pool.active}
else
  # something failed
  { messages: [@errors||=[]].flatten }
end.to_json
