module SalesforceHelpers
  #Creates a "migration" for a specified Salesforce class.  Eval this in a ActiveRecord::Schema.define() block
  def dumpclass( aclass )
    dumpstr = "  create_table \"" + aclass.table_name + "\", :id => false, :force => true do |t|\n"
    for column in aclass.columns
      dumpstr += "    t.column \"" + column.name + "\", "
      if column.type.to_s.eql?('text') && column.limit.to_i < 1000
        dumpstr += ":string, :limit => " + column.limit
      else
        if column.type.nil?
          dumpstr += ":string, :limit => 255"
        else
          dumpstr += ":" + column.type.to_s
        end
      end
      dumpstr += "\n"
    end
    return dumpstr + "  end\n"
  end

  #Scrapes a single record from Salesforce to the local database
  def scrape( aobj, aclass, adbclass )
    begin
      new_obj = adbclass.new(convert(aobj, aclass))
      new_obj.id = aobj.id
      new_obj.save!
    rescue
      return 1
    end
    return 0
  end

  #Scrapes a whole Salesforce Object harshly- deleting all the local data, and the dumping.  Good for empty tables
  #def hard_update_class(aclass, adbclass)
    #count = 0
    #adbclass.delete_all
    #for aobj in aclass.find(:all, :limit => 0)
      #scrape(aobj, aclass, adbclass)
      #count += 1
    #end
    #return count
  #www.wpfdental.comend  

  #Scrapes a whole Salesforce Object softly.  Only looks for objects that were created/updated since the last scrape.
  def update_class(aclass, adbclass)
    #I honestly don't know why I did it this way.  It isn't very DRY.  There must be a reason, so tinker with caution.
    begin
      lastcreated = adbclass.find(:first, :order => 'created_date desc')
      lastmodified = adbclass.find(:first, :order => 'last_modified_date desc')
      for aobj in aclass.find(:all, :limit => 0, :conditions => 'createddate > ' + (lastcreated.created_date - 18000).to_s(:iso_8601_special))
        scrape(aobj, aclass, adbclass)
      end
      for aobj in aclass.find(:all, :limit => 0, :conditions => 'lastmodifieddate > ' + (lastmodified.last_modified_date - 18000).to_s(:iso_8601_special))
        adbclass.delete(aobj.id)
        scrape(aobj, aclass, adbclass)
      end
    rescue
      begin
        lastcreated = adbclass.find(:first, :order => 'created_date desc')
        lastmodified = adbclass.find(:first, :order => 'last_modified_date desc')
        for aobj in aclass.find(:all, :limit => 0, :conditions => 'created_date > ' + (lastcreated.created_date - 18000).to_s(:iso_8601_special))
          scrape(aobj, aclass, adbclass)
        end
        for aobj in aclass.find(:all, :limit => 0, :conditions => 'last_modified_date > ' + (lastmodified.last_modified_date - 18000).to_s(:iso_8601_special))
          adbclass.delete(aobj.id)
          scrape(aobj, aclass, adbclass)
        end
      rescue
        puts "Skipping " + aclass.to_s
      end
    end
  end

  #Converter for a single object
  def convert ( aobj, aclass )
    hash = {}
    aobj.attributes.each { | key, value | 
      hash[key] = value if aclass.column_names.include?(key)
    }
    hash
  end

  #For some reason the Salesforce didn't interpret the ISO 8601 date format spec correctly
  ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.merge!(
    :iso_8601_special => "%Y-%m-%dT%H:%M:%S-05:00"
  )
end