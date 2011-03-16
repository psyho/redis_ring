module RedisRing

  class Master

    def initialize
      @node_ids = []
      @is_master = false
    end

    def became_master
      return if is_master?

      puts "BECAME MASTER"

      @is_master = true
    end

    def no_longer_is_master
      return unless is_master?

      puts "LOST MASTER STATUS"

      @is_master = false
    end

    def cluster_started
      puts "CLUSTER STARTED"
    end

    def nodes_changed(changed_node_ids)
      return unless is_master?

      new_nodes = changed_node_ids - node_ids
      removed_nodes = node_ids - changed_node_ids

      puts "NODES CHANGED. NEW: #{new_nodes.join(", ")}; REMOVED: #{removed_nodes.join(', ')}"

      self.node_ids = changed_node_ids
    end

    def node_joined(node_id)
    end

    def node_leaving(node_id)
    end

    def is_master?
      return @is_master
    end

    protected

    attr_reader :node_ids

  end

end
