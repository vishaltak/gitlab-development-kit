module Helpers
  class Git
    def clone(repository, dest_path)
      `git clone #{repository} #{dest_path}`
    end
  end
end
