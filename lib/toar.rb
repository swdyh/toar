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

  def self.convert_includes_option(*opt)
    r = []
    opt.flatten.each do |i|
      case i
      when Symbol
        r << i
      when Hash
        i.each do |k, v|
          r << { k => convert_includes_option(v) }
        end
      end
    end
    { include: r }
  end

  module Ar
    def toar(opt = {})
      @toar_opt ||= {}
      @toar_opt[(opt[:name] || '').to_sym] = opt
      include Instance
    end

    def to_ar(json)
      Toar.to_ar(self, json)
    end

    def toar_opt(name = '')
      @toar_opt[name.to_sym]
    end

    module Instance
      def toar_as_json(name = '')
        inc_opt = self.class.toar_opt(name)[:includes]
        self.class
          .includes(inc_opt)
          .find_by(id: self.id)
          .as_json(Toar.convert_includes_option(inc_opt))
      end

      def toar_to_json(name = '')
        toar_as_json(name).to_json
      end
    end
  end
end
