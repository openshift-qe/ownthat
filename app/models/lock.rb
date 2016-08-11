class Lock < ApplicationRecord
  # should we use SQL99 "SIMILAR TO" operator? Not yet, harder to escape.
  scope :like, -> (filter) { where("namespace like ? OR resource like ? OR owner like ?", "%#{filter}%", "%#{filter}%", "%#{filter}%")}
end
