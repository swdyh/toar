require 'toar/version'
require 'json'

# Deserialize JSON to ActiveRecord Model with associations
module Toar
  def self.to_ar(klass, val, base_object = nil)
    d = val.class == Hash ? val.dup : JSON.parse(val)
    obj = base_object || klass.new

    hmt = klass.reflect_on_all_associations(:has_many).reduce({}) do |r, i|
      r[i.options[:through]] = i if i.options[:through]
      r
    end

    d.except(*obj.attributes.keys).each do |k, v|
      as = klass.reflect_on_association(k)
      next unless as

      case as.macro
      when :belongs_to
        d.delete("#{k}_id")
        to_ar(as.klass, v, obj.send("build_#{k}"))
        obj.class_eval do
          define_method("#{k}_id") { obj.send(k).id }
        end
      when :has_one
        to_ar(as.klass, v, obj.send("build_#{k}"))
      when :has_many
        obj.send(k).proxy_association.target =
          v.map { |i| to_ar(as.klass, i) }

        as_th = hmt[k.to_sym]
        if as_th
          obj.send(as_th.name).proxy_association.target =
            v.map { |i| to_ar(as_th.klass, i[as_th.source_reflection_name.to_s]) }
        end
      end
    end
    obj.assign_attributes(d.slice(*obj.attributes.keys))

    obj.instance_eval do
      # prevent save
      def valid?(_context = nil)
        false
      end
    end
    obj
  end
end
