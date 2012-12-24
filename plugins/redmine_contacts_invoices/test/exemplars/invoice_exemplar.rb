class Invoice < ActiveRecord::Base
  generator_for :number, :start => 'INV20121212-1'
  generator_for :author, :method => :next_author
  generator_for :status, :method => :fetch_status

  def self.next_author
    User.generate_with_protected!
  end

  def self.fetch_status
    Random.rand(1..3)
  end
end
