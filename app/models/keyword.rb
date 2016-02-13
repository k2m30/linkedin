class Keyword < ActiveRecord::Base
  def revert!
    update(passed: !passed?)
    self
  end
end