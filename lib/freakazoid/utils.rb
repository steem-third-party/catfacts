require 'rdiscount'
require 'open-uri'

module Freakazoid
  require 'freakazoid/config'
  
  module Utils
    include Krang::Utils
    include Config
    
    BLACKIST_TXT = "#{File.dirname(__FILE__)}/../../support/blacklist.txt"
    
    def random_cat_fact
      cat = nil
      
      loop do
        cat = JSON[open('https://catfact.ninja/fact').read]
        
        redo if File.open(BLACKIST_TXT).readlines.include? cat['fact']
        
        break
      end
      
      cat['fact']
    end
    
    def merge(options = {})
      comment_md = 'support/reply.md'
      comment_body = if File.exist?(comment_md)
        File.read(comment_md)
      end

      raise "Cannot read #{template} template or template is empty." if comment_body.nil?

      merged = comment_body
      
      options.each do |k, v|
        merged = case k
        when :from
          merged.gsub("${#{k}}", [v].flatten.join(', @'))
        else; merged.gsub("${#{k}}", v.to_s)
        end
      end

      case options[:markup]
      when :html then RDiscount.new(merged).to_html
      when :markdown then merged
      end
    end
  end
end
