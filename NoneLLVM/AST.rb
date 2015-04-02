module JS
  class Statement
  end
  class Expression
  end
  class Binary < Expression
  end
  class Assign < Expression
  end
  class Number < Expression
  end
  class String < Expression
  end
  class Variable < Expression
  end
  class Write < Expression
  end
  class Add < Binary; end
  class Sub < Binary; end
  class Mul < Binary; end
  class Div < Binary; end
end
