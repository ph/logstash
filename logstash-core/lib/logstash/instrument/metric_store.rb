# encoding: utf-8
require "concurrent"

module LogStash module Instrument
  # The Metric store the data structure that make sure the data is
  # saved in a retrievable way, this is a wrapper around multiples ConcurrentHashMap
  # acting as a tree like structure.
  class MetricStore
    class ConcurrentMapExpectedError < Exception; end

    def initialize
      @store = Concurrent::Map.new
    end

    # This method use the namespace and key to search the corresponding value of
    # the hash, if it doesn't exist it will create the appropriate namespaces
    # path in the hash and return `new_value`
    #
    # @param [Array] The path where the values should be located
    # @param [Object] The default object if the value is not found in the path
    # @return [Object] Return the new_value of the retrieve object in the tree
    def fetch_or_store(namespaces, key, new_value)
      fetch_or_store_namespaces(namespaces).fetch_or_store(key, new_value)
    end

    
    # This method allow to retrieve values for a specific path,
    # It can also return a hash.
    #
    # Also support `*` as a globbing path
    #
    # @param [Array] The path where values should be located
    # @return nil if the values are not found
    def get(paths)
    end

    private
    # This method iterate through the namespace path and try to find the corresponding 
    # value for the path, if the any part of the path is not found it will 
    # create it.
    #
    # @param [Array] The path where values should be located
    # @raise [ConcurrentMapExpected] Raise if the retrieved object isn't a `Concurrent::Map`
    # @return [Concurrent::Map] Map where the metrics should be saved
    def fetch_or_store_namespaces(namespaces_path)
      path_map = fetch_or_store_namespace_recursively(@store, namespaces_path)
      
      # This mean one of the namespace and key are colliding
      # and we have to deal it upstream.
      unless path_map.is_a?(Concurrent::Map)
        raise ConcurrentMapExpectedError, "Expecting a `Concurrent::map`, class:  #{path_map.class.name} for namespaces_path: #{namespaces_path}"
      end

      return path_map
    end

    def fetch_or_store_namespace_recursively(map, remaining_paths, idx = 0)
      current = remaining_paths[idx]
      
      # we are at the end of the namespace path, break out of the recursion
      return map if current.nil?

      new_map = map.fetch_or_store(current) { Concurrent::Map.new }
      return fetch_or_store_namespace_recursively(new_map, remaining_paths, idx + 1)
    end
  end
end; end
