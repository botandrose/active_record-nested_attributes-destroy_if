require "active_record/nested_attributes/destroy_if/version"
require "active_support/concern"
require "active_record"

module ActiveRecord
  module NestedAttributesDestroyIf
    extend ActiveSupport::Concern

    class_methods do
      def accepts_nested_attributes_for(*attr_names)
        options = { allow_destroy: false, update_only: false }
        options.update(attr_names.extract_options!)
        options.assert_valid_keys(:allow_destroy, :reject_if, :destroy_if, :limit, :update_only)
        options[:reject_if] = REJECT_ALL_BLANK_PROC if options[:reject_if] == :all_blank

        attr_names.each do |association_name|
          if reflection = _reflect_on_association(association_name)
            reflection.autosave = true
            define_autosave_validation_callbacks(reflection)

            nested_attributes_options = self.nested_attributes_options.dup
            nested_attributes_options[association_name.to_sym] = options
            self.nested_attributes_options = nested_attributes_options

            type = (reflection.collection? ? :collection : :one_to_one)
            generate_association_writer(association_name, type)
          else
            raise ArgumentError, "No association found for name `#{association_name}'. Has it been defined yet?"
          end
        end
      end
    end

    private

    def assign_nested_attributes_for_one_to_one_association(association_name, attributes)
      options = nested_attributes_options[association_name]
      if attributes.respond_to?(:permitted?)
        attributes = attributes.to_h
      end
      attributes = attributes.with_indifferent_access
      existing_record = send(association_name)

      if (options[:update_only] || !attributes["id"].blank?) && existing_record &&
          (options[:update_only] || existing_record.id.to_s == attributes["id"].to_s)
        assign_to_or_mark_for_destruction(existing_record, attributes, options[:allow_destroy], options[:destroy_if]) unless call_reject_if(association_name, attributes)

      elsif attributes["id"].present?
        raise_nested_attributes_record_not_found!(association_name, attributes["id"])

      elsif !reject_new_record?(association_name, attributes)
        assignable_attributes = attributes.except(*ActiveRecord::NestedAttributes::UNASSIGNABLE_KEYS)

        if existing_record && existing_record.new_record?
          existing_record.assign_attributes(assignable_attributes)
          association(association_name).initialize_attributes(existing_record)
        else
          method = "build_#{association_name}"
          if respond_to?(method)
            send(method, assignable_attributes)
          else
            raise ArgumentError, "Cannot build association `#{association_name}'. Are you trying to build a polymorphic one-to-one association?"
          end
        end
      end
    end

   def assign_nested_attributes_for_collection_association(association_name, attributes_collection)
      options = nested_attributes_options[association_name]
      if attributes_collection.respond_to?(:permitted?)
        attributes_collection = attributes_collection.to_h
      end

      unless attributes_collection.is_a?(Hash) || attributes_collection.is_a?(Array)
        raise ArgumentError, "Hash or Array expected for attribute `#{association_name}`, got #{attributes_collection.class.name} (#{attributes_collection.inspect})"
      end

      check_record_limit!(options[:limit], attributes_collection)

      if attributes_collection.is_a? Hash
        keys = attributes_collection.keys
        attributes_collection = if keys.include?("id") || keys.include?(:id)
          [attributes_collection]
        else
          attributes_collection.values
        end
      end

      association = association(association_name)

      existing_records = if association.loaded?
        association.target
      else
        attribute_ids = attributes_collection.map { |a| a["id"] || a[:id] }.compact
        attribute_ids.empty? ? [] : association.scope.where(association.klass.primary_key => attribute_ids)
      end

      attributes_collection.each do |attributes|
        if attributes.respond_to?(:permitted?)
          attributes = attributes.to_h
        end
        attributes = attributes.with_indifferent_access

        if attributes["id"].blank?
          unless reject_new_record?(association_name, attributes)
            association.build(attributes.except(*ActiveRecord::NestedAttributes::UNASSIGNABLE_KEYS))
          end
        elsif existing_record = existing_records.detect { |record| record.id.to_s == attributes["id"].to_s }
          unless call_reject_if(association_name, attributes)
            # Make sure we are operating on the actual object which is in the association's
            # proxy_target array (either by finding it, or adding it if not found)
            # Take into account that the proxy_target may have changed due to callbacks
            target_record = association.target.detect { |record| record.id.to_s == attributes["id"].to_s }
            if target_record
              existing_record = target_record
            else
              association.add_to_target(existing_record, :skip_callbacks)
            end

            assign_to_or_mark_for_destruction(existing_record, attributes, options[:allow_destroy], options[:destroy_if])
          end
        else
          raise_nested_attributes_record_not_found!(association_name, attributes["id"])
        end
      end
    end

    def reject_new_record?(association_name, attributes)
      will_be_destroyed?(association_name, attributes) ||
        call_reject_if(association_name, attributes) ||
        call_destroy_if(association_name, attributes)
    end

    def assign_to_or_mark_for_destruction record, attributes, allow_destroy, destroy_if
      record.assign_attributes attributes.except(*ActiveRecord::NestedAttributes::UNASSIGNABLE_KEYS)
      should_destroy =
        has_destroy_flag?(attributes) && allow_destroy ||
        case destroy_if
        when Symbol
          method(destroy_if).arity == 0 ? send(destroy_if) : send(destroy_if, attributes)
        when Proc
          destroy_if.call(attributes)
        end
      record.mark_for_destruction if should_destroy
    end

    def call_destroy_if(association_name, attributes)
      return false if will_be_destroyed?(association_name, attributes)

      case callback = nested_attributes_options[association_name][:destroy_if]
      when Symbol
        method(callback).arity == 0 ? send(callback) : send(callback, attributes)
      when Proc
        callback.call(attributes)
      end
    end
  end
end

ActiveRecord::Base.include ActiveRecord::NestedAttributesDestroyIf

