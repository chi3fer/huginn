require 'nokogiri'
require 'date'

module Agents
  class WebsiteAgent < Agent
    include WebRequestConcern
    can_dry_run!
    can_order_created_events!
    no_bulk_receive!
    default_schedule "every_12h"
    absolute true
    UNIQUENESS_LOOK_BACK = 200
    UNIQUENESS_FACTOR = 3

    description <<~MD
      The Website Agent scrapes a website, XML document, or JSON feed and creates Events based on the results.

      absolute true
    end

    def extract_absolute_url(event)
      return event['url'].to_s.sub(%r{https?://}, '') if event['url']
    end
