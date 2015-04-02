require 'rltk/ast'

module JS
  class Expression < RLTK::ASTNode; end
  class Assign < Expression
    value :name,  String
    child :right, Expression
  end
  class Write < Expression
    value :arg_names, [Expression]
  end
  class Binary < Expression
    child :left,  Expression
    child :right, Expression
  end
  class Number < Expression
    value :value, Float
  end
  class Str < Expression
    value :value, String
  end
  class Variable < Expression
    value :name,  String
  end
  class Add < Binary; end
  class Sub < Binary; end
  class Mul < Binary; end
  class Div < Binary; end

  class Prototype < RLTK::ASTNode
    value :name,  String
    value :arg_names, [String]
  end
  class Call < Expression
		value :name, String

		child :args, [Expression]
  end
  class Function < RLTK::ASTNode
    child :proto, Prototype
    child :body,  Expression
  end

end
