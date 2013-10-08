# encoding: utf-8
module Dynamoid #:nodoc:

  # The base association module which all associations include. Every association has two very important components: the source and
  # the target. The source is the object which is calling the association information. It always has the target_ids inside of an attribute on itself.
  # The target is the object which is referencing by this association.
  module Associations
    module Association
      attr_accessor :name, :options, :source, :loaded

      # Create a new association.
      #
      # @param [Class] source the source record of the association; that is, the record that you already have
      # @param [Symbol] name the name of the association
      # @param [Hash] options optional parameters for the association
      # @option options [Class] :class the target class of the association; that is, the class to which the association objects belong
      # @option options [Symbol] :class_name the name of the target class of the association; only this or Class is necessary
      # @option options [Symbol] :inverse_of the name of the association on the target class
      #
      # @return [Dynamoid::Association] the actual association instance itself
      #
      # @since 0.2.0
      def initialize(source, name, options)
        @name = name
        @options = options
        @source = source
        @loaded = false
      end

      def loaded?
        @loaded
      end

      def find_target
      end

      def target
        unless loaded?
          @target = find_target
          @loaded = true
        end

        @target
      end

      def reset
        @target = nil
        @loaded = false
      end

      private
      
      def set(target)
        @target = target
        @loaded = true
      end

      # The target class name, either inferred through the association's name or specified in options.
      #
      # @since 0.2.0
      def target_class_name
        options[:class_name] || name.to_s.classify
      end

      # The target class, either inferred through the association's name or specified in options.
      #
      # @since 0.2.0
      def target_class
        options[:class] || target_class_name.constantize
      end

      # The target attribute: that is, the attribute on each object of the association that should reference the source.
      #
      # @since 0.2.0
      def target_attribute
        association = target_association
        if association
          case target_class.associations[association][:type]
          when :has_one, :belongs_to
            "#{association.name}_id".to_sym
          when :has_many, :has_and_belongs_to_many
            "#{association.to_s.singularize}_ids".to_sym
          end
        end
      end

      # The ids in the target association.
      #
      # @since 0.2.0
      def target_ids
        case target_class.associations[target_association][:type]
        when :has_one, :belongs_to
          id = target.send(target_attribute) if target
          (id && Set[id]) || Set.new
        when :has_many, :has_and_belongs_to_many
          (target && target.send(target_attribute)) || Set.new
        end
      end

      # The ids in the target association.
      #
      # @since 0.2.0
      def source_class
        source.class
      end

      # The source's association attribute: the name of the association with "_id" or "_ids"
      # afterwards, like "user_ids".
      #
      # @since 0.2.0
      def source_attribute
        if self.respond_to? :count
          "#{self.name.to_s.singularize}_ids".to_sym
        else
          "#{self.name}_id".to_sym
        end
      end

      # Associate a source object to this association.
      #
      # @since 0.2.0
      def associate_target(object)
        case target_class.associations[target_association][:type]
        when :has_one, :belongs_to
          object.update_attribute(target_attribute, source.id)
        when :has_many, :has_and_belongs_to_many
          object.update_attribute(target_attribute, target_ids.merge(Array(source.id)))
        end
      end

      # Disassociate a source object from this association.
      #
      # @since 0.2.0      
      def disassociate_target(object)
        case target_class.associations[target_association][:type]
        when :has_one, :belongs_to
          object.update_attribute(target_attribute, nil)
        when :has_many, :has_and_belongs_to_many
          object.update_attribute(target_attribute, object.send(target_attribute) - Array(source.id))
        end
      end
    end
  end

end
