require 'nokogiri'
require 'date'

module Agents
  class WebsiteAgent < Agent
    include WebRequestConcern
    can_dry_run!
    can_order_created_events!
    no_bulk_receive!
    default_schedule "every_12h"
    UNIQUENESS_LOOK_BACK = 200
    UNIQUENESS_FACTOR = 3

    description <<~MD
      The Website Agent scrapes a website, XML document, or JSON feed and creates Events based on the results.

      Specify a `url` and select a `mode` for when to create Events based on the scraped data, either `all`, `on_change`, or `merge` (if fetching based on an Event, see below).

      The `url` option can be a single url, or an array of urls (for example, for multiple pages with the exact same structure but different content to scrape).

      The WebsiteAgent can also scrape based on incoming events.

      * Set the `url_from_event` option to a [Liquid](https://github.com/huginn/huginn/wiki/Formatting-Events-using-Liquid) template to generate a url to access based on the Event.  (To fetch the url in the Event's `url` key, for example, set `url_from_event` to `{{ url }}`.)
      * Alternatively, set the `data_from_event` to a [Liquid](https://github.com/huginn/huginn/wiki/Formatting-Events-using-Liquid) template to use data directly without fetching any URL.  (For example, set it to `{{ html }}` to use HTML contained in the `html` key of the incoming Event.)
      * If you specify `merge` for the `mode` option, Huginn will retain the old payload and update it with new values.

      # Supported Document Types

      The `type` value can be `xml`, `html`, `json`, or `text`.

      To tell the Agent how to parse the content, specify `extract` as a hash with keys naming the extractions and values of hashes.

      Note that for all of the formats, whatever you extract MUST have the same number of matches for each extractor except when it has `repeat` set to true.  E.g., if you're extracting rows, all extractors must match all rows.  For generating CSS selectors, something like [SelectorGadget](http://selectorgadget.com) may be helpful.

      For extractors with `hidden` set to true, they will be excluded from the payloads of events created by the Agent, but can be used and interpolated in the `template` option explained below.

      For extractors with `repeat` set to true, their first matches will be included in all extracts.  This is useful such as when you want to include the title of a page in all events created from the page.

      # Scraping HTML and XML

      When parsing HTML or XML, these sub-hashes specify how each extraction should be done.  The Agent first selects a node set from the document for each extraction key by evaluating either a CSS selector in `css` or an XPath expression in `xpath`.  It then evaluates an XPath expression in `value` (default: `.`) on each node in the node set, converting the result into a string.  Here's an example:

          "extract": {
            "url": { "css": "#comic img", "value": "@src" },
            "title": { "css": "#comic img", "value": "@title" },
            "body_text": { "css": "div.main", "value": "string(.)" },
            "page_title": { "css": "title", "value": "string(.)", "repeat": true }
          }
