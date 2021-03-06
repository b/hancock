class Hancock::Consumer
  include DataMapper::Resource

  property :id,           Serial
  property :url,          String,  :nullable => false, :unique => true, :unique_index => true, :length => 1024
  property :label,        String,  :nullable => true,  :default => nil
  property :internal,     Boolean, :nullable => false, :defalut  => false

  def self.allowed?(host)
    !first(:url => host).nil?
  end

  def self.visible
    all(:internal => false).select do |c|
      c.label
    end
  end

  def self.internal
    all(:internal => true).select do |c|
      c.label
    end
  end
end
