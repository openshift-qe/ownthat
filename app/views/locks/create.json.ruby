if @persisted && !(@errors && !@errors.empty?)
  # success response
  { namespace: @lock.namespace, resource: @lock.resource,
    expires: @lock.expires, owner: @lock.owner }
else
  # something failed
  { messages: [@errors||=[]].flatten }
end.to_json
