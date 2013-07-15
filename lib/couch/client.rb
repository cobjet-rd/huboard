
require "json/ext"
require "couchrest"

class Huboard


  class Couch

    attr_reader :connection

    def initialize(options={})
      return @connection = Connection.new(options)
    end


    module CUD

      def find(id)
        CouchRest.get(connection.db,id)
      end

      def save(doc)
        puts "===== saving doc  ====="
        clone = doc.clone.merge "cool_stuff" => doc[identifier.to_s].to_s, "meta" => meta
        puts "===== id: #{clone[identifier.to_s]} #{identifier}  ====="
        puts clone
        response = p connection.db.save_doc(clone)
        p CouchRest.head(p "#{connection.db.root}/#{response["id"]}") 
        p connection.head(response["id"])
        #CouchRest.put(connection.db, doc)
      end


      # Creates 
      #
      # return json
      #
      def create(attributes)
      end

      def get_or_create(doc)
        clone = doc.clone.merge "_id" => doc[identifier.to_s].to_s, "meta" => meta

        doc = connection.get(clone["_id"])

        return doc.body if doc.status == 200

        response = connection.put(clone["_id"], p(clone))

        response.body.merge clone
      end

      # Patchs 
      #
      # return json
      #
      def patch(attributes)
      end

      # Destroys 
      #
      # return boolean
      #
      def destroy
      end
    end

    class Connection < Faraday::Connection

      attr_reader :db

      # Instantiates connection, accepts an options hash
      # for authenticated access
      #
      def initialize(hash={})
        puts "initializing db"
        @db = CouchRest.database!("#{hash[:base_url] || "http://127.0.0.1:5984" }/huboard")
        
        super("#{hash[:base_url] || "http://127.0.0.1:5984" }/huboard") do |builder|
          yield builder if block_given?
          builder.use     FaradayMiddleware::EncodeJson
          builder.use     FaradayMiddleware::Mashify
          builder.use     FaradayMiddleware::ParseJson
          #  builder.use     Ghee::Middleware::UriEscape
          builder.adapter Faraday.default_adapter

        end


      end

    end

    class ResourceProxy

      module ClassMethods
        def identify_by(symbol)
          class_eval <<-EOS, __FILE__, __LINE__ + 1
            def identifier
              return @identifier ||= "#{symbol}"
            end
          EOS
        end
      end
      # Undefine methods that might get in the way
      instance_methods.each { |m| undef_method m unless m =~ /^__|instance_eval|instance_variable_get|object_id|respond_to/ }

      include CUD
      extend ClassMethods

      # Make connection and path_prefix readable
      attr_reader :connection, :meta, :identifier

      # Expose pagination data
      attr_reader :current_page, :total, :pagination

      # Instantiates proxy with the connection
      # and path_prefix
      #
      # connection - Ghee::Connection object
      # path_prefix - String
      #
      def initialize(connection, meta)
        @connection, @meta = connection, meta
      end

      # Method_missing takes any message passed
      # to the ResourceProxy and sends it to the
      # real object
      #
      # message - Message object
      # args* - Arguements passed
      #

      #def method_missing(message, *args, &block)
      #  subject.send(message, *args, &block)
      #end

      # Subject is the response body parsed
      # as json
      #
      # Returns json
      #
      def subject
        @subject ||= connection.get(path_prefix){|req| req.params.merge!params }.body
      end

    end
    def users
      puts "return user proxy"
      return Users.new(connection,  :type => "user" )
    end

    class Users < ResourceProxy
      identify_by :id

    end
  end
end
