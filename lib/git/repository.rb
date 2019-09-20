module Git
  class Repository
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def untracked_files
      ::Git.run(%w[ls-files --others --exclude-standard], @path)
    end

    def changed_files(target)
      ::Git.run(%W[diff --name-only HEAD #{target}], @path)
    end
  end
end
