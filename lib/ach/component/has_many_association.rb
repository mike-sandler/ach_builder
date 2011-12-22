module ACH
  # Objects of this class host essential functionality required to create
  # associated object from within owner objects.
  #
  # Newly instantiated +HasManyAssociation+ object has no owner, and should
  # be used to assign it's copies to owners via +for+ method. This technique
  # has following application:
  #   class Batch < ACH::Component
  #     association = HasManyAssociation.new(:entries)
  #   
  #     association.delegation_methods.each do |method_name|
  #       delegate method_name, :to => '@batches_association'
  #     end
  #   
  #     after_initialize_hooks << lambda{ instance_variable_set('@batches_association', association.for(self)) }
  #     # All these lines of code are macrosed by <tt>ACH::Component.has_many</tt> method
  #   end
  #   # Now, whenever new batch is created, it will have it's own @batches_association,
  #   # and essential methods +batches+, +batch+, +build_batch+ delegated to it
  #   # (accordingly, to +container+, +create+, and +build+ methods)
  class Component::HasManyAssociation
    # If Record should be attached to (preceded by) other Record, this
    # exception is raised on attempt to create attachment record without
    # having preceded record. For example, Addenda records should be
    # created after Entry records. Each new Addenda record will be attached
    # to the latest Entry record.
    class NoLinkError < ArgumentError
      def initialize(link, klass)
        super "No #{link} was found to attach a new #{klass}"
      end
    end

    # Exception thrown if an association object, assigned for particular
    # owner object, is used to assign to another owner object
    class DoubleAssignmentError < StandardError
      def initialize(name, owner)
        super "Association #{name} has alredy been assigned to #{owner}"
      end
    end

    attr_reader :name, :linked_to, :proc_defaults
    private :linked_to, :proc_defaults

    def initialize(plural_name, options = {})
      @name = plural_name.to_s
      @linked_to, @proc_defaults = options.values_at(:linked_to, :proc_defaults)
    end

    # Clones +self+ and assigns +owner+ to clone. Also, for newly created
    # clone association that has owner, aliases main methods so that +owner+
    # may delegate to them.
    def for(owner)
      raise DoubleAssignmentError.new(@name, @owner) if @owner

      clone.tap do |association|
        plural, singular = name, singular_name
        association.instance_variable_set('@owner', owner)
        association.singleton_class.class_eval do
          alias_method "build_#{singular}", :build
          alias_method singular, :create
          alias_method plural, :container
        end
      end
    end

    # Returns an array of methods to be delegated by +owner+ of the association.
    # For example, for association named :items, it will include:
    # * +build_item+ - for instantiating Item from the string (used by parsing functionality)
    # * +item+ - for instantiating Item during common ACH File creation
    # * +items+ - that returns set of Item objects
    def delegation_methods
      ["build_#{singular_name}", singular_name, name]
    end

    # Uses <tt>klass#from_s</tt> to instantiate object from a string. Thus, +klass+ should be
    # descendant of ACH::Record::Base. Then pushes object to appropriate container.
    def build(str)
      obj = klass.from_s(str)
      container_for_associated << obj
    end

    # Creates associated object using common to ACH controls pattern, and pushes it to
    # appropriate container. For example, for :items association, this method is
    # aliased to +item+, so you will have:
    #   item(:code => 'WEB') do
    #     other_code 'BEW'
    #     # ...
    #   end
    def create(*args, &block)
      fields = args.first || {}

      defaults = proc_defaults ? @owner.instance_exec(&proc_defaults) : {}

      klass.new(@owner.fields_for(klass).merge(defaults).merge(fields)).tap do |component|
        component.instance_eval(&block) if block
        container_for_associated << component
      end
    end

    # Returns main container for association. For plain (without :linked_to option), it is
    # array. For linked associations, it is a hash, which keys are records from linking
    # associations, and values are arrays for association's objects
    def container
      @container ||= linked? ? {} : []
    end

    # Returns array for associated object to be pushed in. For plain associations, it is
    # equivalent to +container+. For linked associations, uses +@owner+ and linking
    # association's name to get the latest record from linking associations. If it does
    # not exist, +NoLinkError+ will be raised.
    #
    # Example:
    #   class Batch < ACH::Component
    #     has_many :entries
    #     has_many :addendas, :linked_to => :entries
    #   end
    #   batch = Batch.new
    #   batch.entry(:amount => 100)
    #   batch.addenda(:text => 'Foo')
    #   batch.entry(:amount => 200)
    #   batch.addenda(:text => 'Bar')
    #   batch.addenda(:text => 'Baz')
    #   
    #   batch.entries  # => [<Entry, amount=100>, <Entry, amount=200>]
    #   batch.addendas # => {<Entry, amount=100> => [<Addenda, text='Foo'>],
    #                  #     <Entry, amount=200> => [<Addenda, text='Bar'>, <Addenda, text='Baz'>]}
    def container_for_associated
      return container unless linked?

      last_link = @owner.send(linked_to).last
      raise NoLinkError.new(linked_to.to_s.singularize, klass.name) unless last_link
      container[last_link] ||= []
    end

    # Returns +true+ if association is linked to another association (thus, it's records must
    # be preceded by other association's records). Returns +false+ otherwise
    def linked?
      !!linked_to
    end
    private :linked?

    # Returns +klass+ that corresponds to association name. Should be defined either in
    # ACH module, or in ACH::Record module
    def klass
      @klass ||= ACH.to_const(@name.classify.to_sym)
    end
    private :klass

    # Returns singular name of the association
    def singular_name
      @singular_name ||= name.singularize
    end
    private :singular_name
  end
end