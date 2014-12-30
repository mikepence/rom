require 'rom/model_builder'

require 'rom/mapper_builder/attribute_dsl'

module ROM
  # @api private
  class MapperBuilder
    include ModelDSL

    attr_reader :name, :root, :prefix, :symbolize_keys, :attributes

    DEFAULT_PROCESSOR = :transproc

    def initialize(name, root, options = {})
      @name = name
      @options = options
      @root = root
      @prefix = options[:prefix]
      @symbolize_keys = options[:symbolize_keys]

      @attributes =
        if options[:inherit_header]
          root.header.map { |attr| [prefix ? :"#{prefix}_#{attr}" : attr] }
        else
          []
        end

      @processor = DEFAULT_PROCESSOR

      super
    end

    def processor(identifier = nil)
      if identifier
        @processor = identifier
        self
      else
        @processor
      end
    end

    def attribute(name, options = {})
      dsl = AttributeDSL.new(@options)
      dsl.attribute(name, options)
      add_attributes(dsl.attributes)
    end

    def exclude(name)
      attributes.delete([name])
    end

    def embedded(name, options = {}, &block)
      dsl = AttributeDSL.new(@options.merge(options))
      dsl.embedded(name, options, &block)
      add_attributes(dsl.attributes)
    end

    def group(*args, &block)
      dsl = AttributeDSL.new(@options)
      dsl.group(*args, &block)
      add_attributes(dsl.attributes)
    end

    def wrap(*args, &block)
      dsl = AttributeDSL.new(@options)
      dsl.wrap(*args, &block)
      add_attributes(dsl.attributes)
    end

    def call
      header = Header.coerce(attributes, model)
      Mapper.build(header, processor)
    end

    private

    def add_attributes(attrs)
      Array(attrs).each do |attr|
        exclude(attr.first.to_s)
        exclude(attr.first)
        exclude(attr.last[:from])
        attributes << attr
      end
    end
  end
end
