class Channel < ActiveRecord::Base
  belongs_to :account
  has_many :campaigns
  
  validates_presence_of :name, :channel_type
  validates_uniqueness_of :name, :case_sensitive => false, :scope => "account_id"
  
  SEO = "seo"
  SEM = "sem"
  BASIC = "basic"
  
  CHANNEL_TYPES = [SEO, SEM, BASIC]
  CHANNEL_TYPE_OPTIONS = [['SEO Channel', SEO], ['SEM Channel', SEM], ['Basic Channel', BASIC]].to_ordered_hash
  
  validates_inclusion_of :channel_type, :in => CHANNEL_TYPES
  
  
  # INSTANCE BEHAVIOR
  
  def set_type_seo
    self.channel_type = SEO
  end
  
  def set_type_sem
    self.channel_type = SEM
  end
  
  def set_type_basic
    self.channel_type = BASIC
  end
  
  
  # PREDICATES
  
  def is_seo?
    self.channel_type == SEO
  end
  
  def is_sem?
    self.channel_type == SEM
  end
  
  def is_basic?
    self.channel_type == BASIC
  end
end
