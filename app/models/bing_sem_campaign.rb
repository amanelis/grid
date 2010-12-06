require 'soap/wsdlDriver'
require 'soap/header/simplehandler'
require 'soap/baseData'

NS_SHARED = "https://adcenter.microsoft.com/v7"

# This is a helper class that is used
# to construct the request header.
class RequestHeader < SOAP::Header::SimpleHandler
    def initialize (element, value)
        super(XSD::QName.new(NS_SHARED, element))
            @element = element
            @value   = value
    end

    def on_simple_outbound
        @value
    end
end

def GetAllCampaigns(username, password, appToken, devToken, customerAccountId, customerId, accountId)

    # Create the WSDL driver reference to access the Web service.
    wsdl = SOAP::WSDLDriverFactory.new("https://sandboxapi.adcenter.microsoft.com/Api/Advertiser/v7/CampaignManagement/CampaignManagementService.svc?wsdl")

    # Create an instance of the CampaignManagement Web service.
    service = wsdl.create_rpc_driver

    # For SOAP debugging information,
    # uncomment the following statement.
    # service.wiredump_dev = STDERR

    # Set the request header information.
    service.headerhandler << RequestHeader.new('ApplicationToken',
        "#{appToken}")
    service.headerhandler << RequestHeader.new('CustomerAccountId',
        "#{customerAccountId}")
    service.headerhandler << RequestHeader.new('CustomerId',
        "#{customerId}")
    service.headerhandler << RequestHeader.new('DeveloperToken',
        "#{devToken}")
    service.headerhandler << RequestHeader.new('UserName',
        "#{username}")
    service.headerhandler << RequestHeader.new('Password',
        "#{password}")

    request = 
    {
        :AccountId => "#{accountId}"
    }

    begin
        # Perform the service operation.
        result = service.getCampaignsByAccountId(request)

        campaigns = result.campaigns.campaign

        if !campaigns.respond_to?('each')
            campaigns = [campaigns]
        end

        for campaign in campaigns
            puts campaign.name
        end

    # Exception handling.
    rescue SOAP::FaultError => fault
        detail = fault.detail

        if detail.respond_to?('adApiFaultDetail')

            # Get the AdApiFaultDetail object.
            adApiErrors = detail.adApiFaultDetail.errors.adApiError

            if !adApiErrors.respond_to?('each')
                adApiErrors = [adApiErrors]
            end

            adApiErrors.each do |error|
                print "Ad API error" \
                    " '#{error.message}' (#{error.code}) encountered.\n"
            end

        # Capture adCenter API exceptions.
        elsif detail.respond_to?('apiFaultDetail')
            operationErrors = \
                detail.operationErrors.operationError

            if !operationErrors.respond_to?('each')
                operationErrors = [operationErrors]
            end

            operationErrors.each do |opError|
                print "Operation error" \
                    " '#{opError.message}' (#{opError.code}) encountered.\n"
            end

        # Capture any generic SOAP exceptions.
        else
            print "Generic SOAP fault" \
                " '#{detail.exceptionDetail.message}' encountered.\n"
        end

    # Capture exceptions on the client that are unrelated to
    # the adCenter API. An example would be an 
    # out-of-memory condition on the client.
    rescue Exception => e
        puts "Error '#{e.exception.message}' encountered."
    end
end
