# frozen_string_literal: true

class SemVer < Gem::Version
  def <=>(v2)
    v2 = self.class.new(v2) unless v2.instance_of?(SemVer)

    super(v2)
  end

  def major
    _segments[0]
  end

  def minor
    _segments[1] || 0
  end

  def patch
    _segments[2] || 0
  end

  def major_match?(v2)
    v2 = self.class.new(v2) unless v2.instance_of?(SemVer)

    major == v2.major
  end

  def major_minor_match?(v2)
    v2 = self.class.new(v2) unless v2.instance_of?(SemVer)
    return false unless major_match?(v2)

    minor == v2.minor
  end
end
