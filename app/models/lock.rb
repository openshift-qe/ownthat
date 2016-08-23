class Lock < ApplicationRecord
  # should we use SQL99 "SIMILAR TO" operator? Not yet, harder to escape.
  scope :like, -> (filter) { where("namespace like ? OR resource like ? OR owner like ?", "%#{filter}%", "%#{filter}%", "%#{filter}%")}

  # when we want to construct persisted object without invalidating DB cache
  def get_by_resource
    Lock.where(namespace: self.namespace, resource: self.resource)[0]
  end
end
