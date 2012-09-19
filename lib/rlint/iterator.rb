module Rlint
  ##
  # {Rlint::Iterator} is a class that can be used to iterate over the AST
  # generated by {Rlint::Parser} and execute callback methods for each
  # encountered node. Basic usage is as following:
  #
  #     code = <<-CODE
  #     [10, 20].each do |number|
  #       puts number
  #     end
  #     CODE
  #
  #     parser   = Rlint::Parser.new(code)
  #     tokens   = parser.parse
  #     iterator = Rlint::Iterator.new
  #
  #     iterator.iterate
  #
  # This particular example doesn't do anything but iterating over the nodes
  # due to no callback classes being defined. How to add these classes is
  # discussed below.
  #
  # ## Callback Classes
  #
  # Without any custom callback classes the iterator class is fairly useless as
  # it does nothing but iterate over all the nodes. These classes are defined
  # as any ordinary class and are added to an interator instance using
  # {Rlint::Iterator#bind}. At the most basic level each callback class should
  # have the following structure:
  #
  #     class MyCallback
  #       def initialize(report)
  #         @report = report
  #       end
  #     end
  #
  # The constructor method should take a single parameter which is used for
  # storing an instance of {Rlint::Report} (see the documentation of that class
  # for more information about it). To make this, as well as adding errors and
  # such to a report easier your own classes can extend {Rlint::Callback}:
  #
  #     class MyCallback < Rlint::Callback
  #
  #     end
  #
  # To add your class to an iterator instance you'd run the following:
  #
  #     iterator = Rlint::Iterator.new
  #
  #     iterator.bind(MyCallback)
  #
  # ## Callback Methods
  #
  # When iterating over an AST the method {Rlint::Iterator#iterator} calls two
  # callback methods based on the event name stored in the token (in
  # {Rlint::Token::Token#event}):
  #
  # * `on_EVENT_NAME`
  # * `after_EVENT_NAME`
  #
  # Where `EVENT_NAME` is the name of the event. For example, for strings this
  # would result in the following methods being called:
  #
  # * `on_string`
  # * `after_string`
  #
  # Note that the "after" callback is not executed until all child nodes have
  # been processed.
  #
  # Each method should take a single parameter that contains details about the
  # token that is currently being processed. Each token is an instance of
  # {Rlint::Token::Token} or one of its child classes.
  #
  # If you wanted to display the values of all strings in your console you'd
  # write the following class:
  #
  #     class StringPrinter < Rlint::Callback
  #       def on_string(token)
  #         puts token.value
  #       end
  #     end
  #
  class Iterator
    ##
    # Array containing a set of instance specific callback objects.
    #
    # @return [Array]
    #
    attr_reader :callbacks

    ##
    # Creates a new instance of the iterator class.
    #
    # @param [Rlint::Report|NilClass] report The report to use, set to `nil` by
    #  default.
    #
    def initialize(report = nil)
      @callbacks = []
      @report    = report
    end

    ##
    # Iterates over the specified array of token classes and executes defined
    # callback methods.
    #
    # @param [#each] nodes An array (or a different object that responds to
    #  `#each()`) that contains a set of tokens to process.
    #
    def iterate(nodes)
      nodes.each do |node|
        next unless node.is_a?(Rlint::Token::Token)

        event_name     = node.event.to_s
        callback_name  = 'on_' + event_name
        after_callback = 'after_' + event_name

        @callbacks.each do |obj|
          if obj.respond_to?(callback_name)
            obj.send(callback_name, node)
          end
        end

        node.child_nodes.each do |child_nodes|
          if child_nodes.respond_to?(:each)
            iterate(child_nodes)
          end
        end

        @callbacks.each do |obj|
          if obj.respond_to?(after_callback)
            obj.send(after_callback, node)
          end
        end
      end
    end

    ##
    # Adds the specified class to the list of callback classes for this
    # instance.
    #
    # @example
    #  iterator = Rlint::Iterator.new
    #
    #  iterator.bind(CustomCallbackClass)
    #
    # @param [Class] callback_class The class to add.
    #
    def bind(callback_class)
      @callbacks << callback_class.new(@report)
    end
  end # Iterator
end # Rlint
