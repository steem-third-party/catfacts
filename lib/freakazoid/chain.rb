module Freakazoid
  require 'freakazoid/utils'
  
  module Chain
    include Krang::Chain
    include Utils
    
    def reset_follow_api
      @follow_api = nil
    end
    
    def follow_api
      @follow_api ||= Radiator::FollowApi.new(chain_options)
    end
    
    def followed_by?(account)
      followers = []
      count = -1

      until count == followers.size
        count = followers.size
        follow_api.get_followers(account_name, followers.last, 'blog', 1000) do |follows, error|
          followers += follows.map(&:follower)
          followers = followers.uniq
        end
      end
      
      followers.include? account
    end
    
    def following?(account)
      following = []
      count = -1

      until count == following.size
        count = following.size
        follow_api.get_following(account_name, following.last, 'blog', 100) do |follows, error|
          following += follows.map(&:following)
          following = following.uniq
        end
      end

      following.include? account
    end
    
    def following_tags?(comment)
      metadata = JSON.parse(comment.json_metadata) rescue {}
      tags = ([metadata['tags']] || []).flatten
      
      return false if (follow_tags & tags).none?
      comment = find_comment(comment.author, comment.permlink)
      
      return false if comment.depth > max_follow_tags_reply_depth
      
      true
    end
    
    def already_replied?(comment)
      !!(api.get_content_replies(comment.author, comment.permlink) do |replies|
        replies.find{ |r| r.author == account_name }
      end || false)
    end
    
    def reply(comment)
      metadata = JSON.parse(comment.json_metadata) rescue {}
      tags = metadata['tags'] || []
      
      # We are using asynchronous replies because sometimes the blockchain
      # rejects replies that happen too quickly.
      thread = Thread.new do
        author = comment.author
        permlink = comment.permlink
        parent_permlink = comment.parent_permlink
        parent_author = comment.parent_author
        votes = []
          
        debug "Replying to #{author}/#{permlink}"
      
        loop do
          merge_options = {
            markup: :html,
            content_type: parent_author == '' ? 'post' : 'comment',
            account_name: account_name,
            author: author,
            body: random_cat_fact
          }
          
          reply_metadata = {
            app: Freakazoid::AGENT_ID
          }
          
          reply_metadata[:tags] = [tags.first] if tags.any?
          reply_permlink = "re-#{author.gsub(/[^a-z0-9\-]+/, '-')}-#{permlink.split('-')[0..5][1..-2].join('-')}-#{Time.now.utc.strftime('%Y%m%dt%H%M%S%Lz')}" # e.g.: 20170225t235138025z
          
          comment = {
            type: :comment,
            parent_permlink: permlink,
            author: account_name,
            permlink: reply_permlink,
            title: '',
            body: merge(merge_options),
            json_metadata: reply_metadata.to_json,
            parent_author: author
          }
          
          if vote_weight != 0 && followed_by?(author)
            votes << {
              type: :vote,
              voter: account_name,
              author: author,
              permlink: permlink,
              weight: vote_weight
            }
          end
          
          if self_vote_weight != 0
            votes << {
              type: :vote,
              voter: account_name,
              author: account_name,
              permlink: reply_permlink,
              weight: self_vote_weight
            }
          end
          
          tx = Radiator::Transaction.new(chain_options.merge(wif: posting_wif))
          
          if follow_back?
            if followed_by?(author) && !following?(author)
              tx.operations << {
                type: :custom_json,
                required_auths: [],
                required_posting_auths: [account_name],
                id: 'follow',
                json: [
                  :follow, {
                    follower: account_name,
                    following: author,
                    what: [:blog]
                  }
                ].to_json
              }
            end
          end
          
          tx.operations << comment
          
          if votes.size > 0
            tx.operations << votes[0]
          end
          
          response = nil
          
          begin
            sleep Random.rand(3..20) # stagger procssing
            semaphore.synchronize do
              response = tx.process(true)
            end
          rescue => e
            warning "Unable to reply: #{e}", e
          end
          
          if !!response && !!response.error
            message = response.error.message
            if message.to_s =~ /You may only comment once every 20 seconds./
              warning "Retrying comment: commenting too quickly."
              sleep Random.rand(20..40) # stagger retry
              redo
            elsif message.to_s =~ /STEEMIT_MAX_PERMLINK_LENGTH: permlink is too long/
              error "Failed comment: permlink too long"
              break
            elsif message.to_s =~ /You have already voted in a similar way./
              error "Failed comment/vote: Already voted/commented (original author did an edit)."
              break
            elsif message.to_s =~ /missing required posting authority/
              error "Failed vote: Check posting key."
              break
            elsif message.to_s =~ /bandwidth limit exeeded/
              error "Failed comment: bandwidth limit exeeded."
              break
            elsif message.to_s =~ /unknown key/
              error "Failed vote: unknown key (testing?)"
              break
            elsif message.to_s =~ /tapos_block_summary/
              warning "Retrying vote/comment: tapos_block_summary (?)"
              redo
            elsif message.to_s =~ /now < trx.expiration/
              warning "Retrying vote/comment: now < trx.expiration (?)"
              redo
            elsif message.to_s =~ /signature is not canonical/
              warning "Retrying vote/comment: signature was not canonical (bug in Radiator?)"
              redo
            end
          end
          
          info response unless response.nil?
          
          break
        end
          
        begin
          if votes.size > 1
            sleep 3
            tx = Radiator::Transaction.new(chain_options.merge(wif: posting_wif))
            tx.operations << votes[1]
            tx.process(true)
          end
        rescue => e
          warning "Unable to vote: #{e}", e
        end
      end
    end
  end
end

