module RubyLint
  ##
  # {RubyLint::FileScanner} is used for finding a list of files that could
  # potentially define a given Ruby constant (path).
  #
  # @!attribute [r] directories
  #  @return [Array]
  #
  # @!attribute [r] ignore
  #  @return [Array]
  #
  class FileScanner
    attr_reader :directories, :ignore

    ##
    # Array containing names of directories that (often) contain Ruby source
    # files.
    #
    # @return [Array]
    #
    RUBY_DIRECTORIES = %w{app lib}

    ##
    # @return [Array]
    #
    def self.default_directories
      directories = []

      RUBY_DIRECTORIES.each do |dir|
        path = File.join(Dir.pwd, dir)

        directories << path if File.directory?(path)
      end

      return directories
    end

    ##
    # @param [Array] directories A collection of base directories to search in.
    # @param [Array] ignore A list of paths to ignore.
    #
    def initialize(directories = self.class.default_directories, ignore = [])
      unless directories.respond_to?(:each)
        raise TypeError, 'Directories must be specified as an Enumerable'
      end

      @directories = directories
      @ignore      = ignore || []

      # Hash that will contain the matching file paths for a given constant.
      @constant_paths_cache = {}
    end

    ##
    # Tries to find `constant` in one of the directories. The return value is
    # an Array of file paths sorted from top-level to deeply nested structures
    # (e.g. `a.rb` comes before `foo/a.rb`).
    #
    # @param [String] constant
    # @return [Array]
    #
    def scan(constant)
      @glob_cache ||= directories.empty? ? [] : glob_ruby_files

      unless constant_paths_cached?(constant)
        build_constant_paths_cache(constant)
      end

      return @constant_paths_cache[constant]
    end

    ##
    # @return [Array]
    #
    def glob_ruby_files
      return Dir.glob("{#{directories.join(',')}}/**/*.rb")
    end

    private

    ##
    # Searches all the files that could potentially define the given constant
    # and caches them.
    #
    # @param [String] constant
    #
    def build_constant_paths_cache(constant)
      paths = match_globbed_files(constant_to_path(constant))

      # Lets see if we can find anything when using dashes for the directory
      # names instead of underscores.
      if paths.empty?
        paths = match_globbed_files(constant_to_dashed_path(constant))
      end

      paths.map! { |p| File.expand_path(p) }

      ignore.each do |pattern|
        paths.reject! do |path|
          path.include?(pattern)
        end
      end

      # Ensure that the order is from top-level -> deeply nested files
      # instead of a random order.
      paths.sort! do |left, right|
        left.length <=> right.length
      end

      @constant_paths_cache[constant] = paths
    end

    ##
    # @return [Array]
    #
    def match_globbed_files(segment)
      # Ensure that we match entire path segments. Just using the segment would
      # result in partial filename matching (e.g. "foo.rb" matching
      # "bar_foo.rb"). We don't want that.
      segment = "/#{segment}"

      return @glob_cache.select { |p| p.include?(segment) }
    end

    ##
    # @return [TrueClass|FalseClass]
    #
    def constant_paths_cached?(constant)
      return @constant_paths_cache.key?(constant)
    end

    ##
    # @param [String] constant
    # @return [String]
    #
    def constant_to_path(constant)
      return constant.gsub('::', '/').snake_case + '.rb'
    end

    ##
    # @see #constant_to_path
    #
    def constant_to_dashed_path(constant)
      segments = constant.split('::')
      last     = segments[-1]
      prefix   = segments[0..-2].join('/').snake_case.gsub('_', '-')

      unless prefix.empty?
        prefix += '/'
      end

      return "#{prefix}#{last.snake_case}.rb"
    end

    ##
    # @param [String] segment
    # @return [String]
    #
    def glob_pattern(segment)
      return "{#{directories.join(',')}}/**/#{segment}.rb"
    end
  end # FileScanner
end # RubyLint
