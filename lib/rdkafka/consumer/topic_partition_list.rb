module Rdkafka
  class Consumer
    # A list of topics with their partition information
    class TopicPartitionList
      # Create a new topic partition list.
      #
      # @param pointer [::FFI::Pointer, nil] Optional pointer to an existing native list
      #
      # @return [TopicPartitionList]
      def initialize(pointer=nil)
        @tpl =
          Rdkafka::FFI::TopicPartitionList.new(
            ::FFI::AutoPointer.new(
              pointer || Rdkafka::FFI.rd_kafka_topic_partition_list_new(5),
              Rdkafka::FFI.method(:rd_kafka_topic_partition_list_destroy)
            )
        )
      end

      # Number of items in the list
      # @return [Integer]
      def count
        @tpl[:cnt]
      end

      # Whether this list is empty
      # @return [Boolean]
      def empty?
        count == 0
      end

      # Adds a topic with unassigned partitions to the list.
      #
      # @param topic [String] The topic's name
      #
      # @return [nil]
      def add_unassigned_topic(topic)
        add_topic_partition(topic, -1)
      end

      # Adds a topic with a partition to the list.
      #
      # @param topic [String] The topic's name
      # @param partition [Integer] The topic's partition
      #
      # @return [nil]
      def add_topic_partition(topic, partition)
        Rdkafka::FFI.rd_kafka_topic_partition_list_add(
          @tpl,
          topic,
          partition
        )
      end

      # Return a `Hash` with the topics as keys and and an array of partition information as the value if present.
      #
      # @return [Hash<String, [Array<Partition>, nil]>]
      def to_h
        {}.tap do |out|
          count.times do |i|
            ptr = @tpl[:elems] + (i * Rdkafka::FFI::TopicPartition.size)
            elem = Rdkafka::FFI::TopicPartition.new(ptr)
            if elem[:partition] == -1
              out[elem[:topic]] = nil
            else
              partitions = out[elem[:topic]] || []
              partition = Partition.new(elem[:partition], elem[:offset])
              partitions.push(partition)
              out[elem[:topic]] = partitions
            end
          end
        end
      end

      # Human readable representation of this list.
      # @return [String]
      def to_s
        "<TopicPartitionList: #{to_h}>"
      end

      def ==(other)
        self.to_h == other.to_h
      end
    end
  end
end
