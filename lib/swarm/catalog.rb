module Swarm
  class Catalog

    class << self

      def count(key)
        instance.synchronize { |categories| categories[key].count }
      end

      def fetch(key, value, default = nil)
        instance.synchronize { |categories| categories[key].fetch value, default }
      end

      def increment(key, value)
        instance.synchronize do |categories|
          categories[key][value] ||= 0
          categories[key][value] += 1
        end
      end

      def store(key, value)
        instance.synchronize { |categories| categories[key].store value, true }
      end

      def delete(key, value)
        instance.synchronize { |categories| categories[key].delete value }
      end

      def flush(key, fetch: :keys)
        instance.synchronize do |categories|
          result = categories.delete(key)
          result ||= Hash.new
          result.send fetch
        end
      end

      def select(*keys, fetch: :keys)
        instance.synchronize do |categories|
          keys.flat_map { |key| categories[key].send fetch }
        end
      end

      def clear(key)
        instance.synchronize { |categories| categories[key].clear }
      end

      def instance
        @instance ||= new
      end

      private :new,
              :instance
    end

    def synchronize
      yield categories
      # transaction.synchronize { yield categories }
    end

    private

    def transaction
      @transaction ||= Mutex.new
    end

    def categories
      @categories ||= Hash.new { |h, k| h[k] = Hash.new }
    end
  end
end

