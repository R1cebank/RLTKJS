require 'rltk/ast'

module JS
  class Expression < RLTK::ASTNode; end
  class Field < Expression
    value :name,  String
    value :expr, Expression
  end
  class Object < Expression
    value :fields, [Field]
  end
  class Assign < Expression
    value :name,  String
    child :right, Expression
  end
  class Write < Expression
    value :arg_names, [Expression]
  end
  class IfStmt < Expression
    value :cond,      Expression
    value :ifBlock,   [Expression]
    value :elseBlock, [Expression]
  end
  class Binary < Expression
    child :left,  Expression
    child :right, Expression
  end
  class Bool < Expression; end
  class True < Bool
    value :value,  TrueClass
  end
  class False < Bool
    value :value,  FalseClass
  end
  class Number < Expression
    value :value, Integer
  end
  class StrLiteral < Expression
    value :value, String
  end
  class ObjVariable < Expression
    value :name,  String
    value :fname, String
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
