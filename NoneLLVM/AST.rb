require 'rltk/ast'

module JS
  class Expression < RLTK::ASTNode
    value :lineno,  Integer
  end
  class Field < Expression
    value :name,  String
    value :expr, Expression
  end
  class Object < Expression
    value :fields, [Field]
  end
  class List < Expression
    value :fields, [Expression]
  end
  class AssignArray < Expression
    value :name,  String
    value :index, Integer
    child :right, Expression
  end
  class AssignObject < Expression
    value :name,  String
    value :fname, String
    child :right, Expression
  end
  class Assign < Expression
    value :name,  String
    child :right, Expression
  end
  class Update < Expression
    value :name,  String
    child :right, Expression
  end
  class Write < Expression
    value :arg_names, [Expression]
  end
  class Loop < Expression
    value :cond,      Expression
    value :block,     [Expression]
  end
  class While < Loop; end
  class DoWhile    < Loop; end
  class IfStmt < Expression
    value :cond,      Expression
    value :ifBlock,   [Expression]
    value :elseBlock, [Expression]
  end
  class Binary < Expression
    child :left,  Expression
    child :right, Expression
  end
  class Undef < Expression
    value :value, String
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
  class ArrayVariable < Expression
    value :name,  String
    value :index, Integer
  end
  class Variable < Expression
    value :name,  String
  end
  class Add < Binary; end
  class Sub < Binary; end
  class Mul < Binary; end
  class Div < Binary; end
  class And < Binary; end
  class Or  < Binary; end
  class Gt  < Binary; end
  class Less < Binary; end
  class GtEq < Binary; end
  class LessEq < Binary; end
  class Eqlv < Binary; end
  class NotEqlv < Binary; end

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
