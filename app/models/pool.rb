class Pool < ApplicationRecord
  validates :name, length: { minimum: 1 }
  validates :resource, length: { minimum: 1 }

  # should we use SQL99 "SIMILAR TO" operator? Not yet, harder to escape.
  scope :like, -> (filter) { where("name like ? OR resource like ?", "%#{filter}%", "%#{filter}%")}

  # when we want to construct persisted object without invalidating DB cache
  #def get_by_resource
  #  Lock.where(name: self.namespace, resource: self.resource)[0]
  #end
end
