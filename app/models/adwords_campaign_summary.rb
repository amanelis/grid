class AdwordsCampaignSummary < ActiveRecord::Base
  belongs_to :google_sem_campaign

  named_scope :between, lambda { |start_date, end_date| {:conditions => ['report_date between ? AND ?', start_date, end_date]} }

end
