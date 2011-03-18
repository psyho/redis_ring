module RedisRing

  class Master

    attr_reader :zookeeper_connection, :ring_size, :node_provider

    def initialize(zookeeper_connection, ring_size, node_provider)
      @zookeeper_connection = zookeeper_connection
      @ring_size = ring_size
      @node_provider = node_provider
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

    def nodes_changed(changed_node_ids)
      return unless is_master?

      new_nodes = changed_node_ids - node_ids
      removed_nodes = node_ids - changed_node_ids

      puts "NODES CHANGED"
      puts "NEW: #{new_nodes.join(", ")}" if new_nodes.any?
      puts "REMOVED: #{removed_nodes.join(', ')}" if removed_nodes.any?

      @node_ids = changed_node_ids

      reassign_shards
    end

    def node_joined(node_id)
      puts "NODE JOINED #{node_id}"

      reassign_shards
    end

    def node_leaving(node_id)
      puts "NODE LEAVING #{node_id}"

      node_ids.delete(node_id)
      reassign_shards
    end

    def is_master?
      return @is_master
    end

    def reassign_shards
      update_node_statuses

      running_shards = {}
      best_candidates = {}
      best_candidates_timestamps = Hash.new(0)

      nodes.each do |node_id, node|
        node.running_shards.dup.each do |shard_no|
          if running_shards.key?(shard_no)
            node.stop_shard(shard_no)
          else
            running_shards[shard_no] = node_id
          end
        end

        node.available_shards.each do |shard_no, timestamp|
          if timestamp > best_candidates_timestamps[shard_no]
            best_candidates[shard_no] = node_id
            best_candidates_timestamps[shard_no] = timestamp
          end
        end
      end

      offline_shards = (0...ring_size).to_a - running_shards.keys
      shards_per_node = (1.0 * ring_size / nodes.size).floor
      rest = ring_size - shards_per_node * nodes.size

      nodes.each do |node_id, node|
        next unless node.joined?
        break if offline_shards.empty?
        count_to_assign = shards_per_node - node.running_shards.size
        count_to_assign += 1 if node_ids.index(node_id) < rest
        count_to_assign.times do
          shard_no = offline_shards.shift
          break unless shard_no
          node.start_shard(shard_no)
        end
      end
    end

    protected

    attr_reader :node_ids
    attr_accessor :nodes

    def update_node_statuses
      self.nodes ||= {}

      nodes.each do |node_id, node|
        unless node_ids.include?(node_id)
          nodes.delete(node_id)
        end
      end

      node_ids.each do |node_id|
        next if nodes.key?(node_id)
        node_data = zookeeper_connection.node_data(node_id)
        nodes[node_id] = node_provider.new(node_data["host"], node_data["port"])
      end

      nodes.each do |node_id, node|
        node.update_status!
      end
    end

  end

end
