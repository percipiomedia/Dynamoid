# encoding: utf-8
module Dynamoid #:nodoc:

  module Associations
    module SingleAssociation
      include Association

      delegate :class, :to => :target

      def setter(object)
        delete unless source.send(source_attribute).nil?
        if object
          raise Dynamoid::Errors::Error.new("Cannot reference object #{object.inspect} without ID.") if object.id.nil?
          raise Dynamoid::Errors::Error.new("Cannot create inverse association on object #{self.inspect} without ID.") if target_association && source.id.nil?
          set(object)
          source.update_attribute(source_attribute, object.id)
          self.send(:associate_target, object) if target_association
        end
        object
      end

      def delete
        self.send(:disassociate_target, target) if target && target_association
        reset
        source.update_attribute(source_attribute, nil)
        target
      end

      def create!(attributes = {})
        setter(target_class.create!(attributes))
      end

      def create(attributes = {})
        setter(target_class.create!(attributes))
      end


      # Is this object equal to the association's target?
      #
      # @return [Boolean] true/false
      #
      # @since 0.2.0
      def ==(other)
        target == other
      end

      # Delegate methods we don't find directly to the target.
      #
      # @since 0.2.0
      def method_missing(method, *args)
        if target.respond_to?(method)
          target.send(method, *args)
        else
          super
        end
      end

      def nil?
        target.nil?
      end

      private

      # Find the target of the has_one association.
      #
      # @return [Dynamoid::Document] the found target (or nil if nothing)
      #
      # @since 0.2.0
      def find_target
        return if source_ids.empty?
        target_class.find(source_ids.first)
      end

      # The ids in the source association.
      #
      # @since 0.2.0
      def source_ids
        id = source.send(source_attribute)
        (id && Set[id]) || Set.new
      end
    end
  end
end
