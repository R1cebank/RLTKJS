module JS
  class Contractor
    def initialize
      # add a new local map
      @st = Hash.new
      @st["true"] = True.new(0, true)
      @st["false"] = False.new(0, false)
    end
    def add(ast)
      case ast
      when Expression then visit ast
      when Function, Prototype then visit ast
      else raise 'Attempting to ass an unhandled node type to JIT.'
      end
    end
    def visit(ast)
      if ast == nil
        return nil
      end
      case ast
      when Assign then
        right = visit(ast.right)
        if @st.has_key?(ast.name)
          @st[ast.name] = right
          return nil
        else
          @st[ast.name] = right
          return nil
        end
      when AssignArray then
        right = visit(ast.right)
        if @st.has_key?(ast.name)
          @st[ast.name][ast.index] = right
          return nil
        else
          return nil
        end
      when While then
        cond = visit(ast.cond)
        if cond.value
          ast.block.map { |stmt| visit(stmt)  }
          visit(ast)
        end
      when DoWhile then
        ast.block.map { |stmt| visit(stmt)  }
        cond = visit(ast.cond)
        if cond.value
          visit(ast)
        end
      when IfStmt then
        cond = visit(ast.cond)
        if cond.value
          ast.ifBlock.map { |stmt| visit(stmt)}
        else
          ast.elseBlock.map {
            |stmt|
            visit(stmt)
          }
        end
      when Variable then
        if @st.key?(ast.name)
          return @st[ast.name]
        else
          puts "Line #{ast.lineno}, #{ast.name} has no value"
          return Undef.new(ast.lineno, "undefined")
        end
      when ObjVariable then
        obj = visit(Variable.new(ast.lineno, ast.name))
        case obj
        when Undef then
          return Undef.new(ast.lineno, "undefined")
        when Hash then
          if obj.key?(ast.fname)
            return obj[ast.fname]
          else
            puts "Line #{ast.lineno}, field #{ast.fname} is not found in object #{ast.name}"
          end
        else puts "Line #{ast.lineno}, #{ast.name} is not an object"
        end
      when ArrayVariable then
        arr = visit(Variable.new(ast.lineno, ast.name))
        return arr[ast.index]
      when Object then
        fields = ast.fields.map { |node| node = visit(node)}
        obj = Hash.new
        fields.each { |field| obj[field.name] = field.expr}
        return obj
      when Field then
        return Field.new(ast.lineno, ast.name, visit(ast.expr))
      when Write then
        args = ast.arg_names.map{ |node| node = visit(node)}
        str = ""
        args.map { |node|
          if node == nil
            str += "undefined"
          elsif node.value.to_s != "<br />"
            str += node.value.to_s
          else
            str += "\n"
          end
        }
        print str
      when And then
        left = visit(ast.left)
        right = visit(ast.right)
        if typecheck(left, right, "JS::Bool") != nil
          val = (left.value && right.value)
          if val
            return @st["true"]
          else
            return @st["false"]
          end
        else
          return nil
        end
      when Or then
        left = visit(ast.left)
        right = visit(ast.right)
        if typecheck(left, right, "JS::Bool") != nil
          val = (left.value || right.value)
          if val
            return @st["true"]
          else
            return @st["false"]
          end
        else
          return nil
        end
      when Gt then
        left = visit(ast.left)
        right = visit(ast.right)
        if type2check(ast.lineno, left, right) != nil
          val = (left.value > right.value)
          if val
            return @st["true"]
          else
            return @st["false"]
          end
        end
      when Less then
        left = visit(ast.left)
        right = visit(ast.right)
        if type2check(left, right) != nil
          val = (left.value < right.value)
          if val
            return @st["true"]
          else
            return @st["false"]
          end
        end
      when GtEq then
        left = visit(ast.left)
        right = visit(ast.right)
        if type2check(left, right) != nil
          val = (left.value >= right.value)
          if val
            return @st["true"]
          else
            return @st["false"]
          end
        end
      when LessEq then
        left = visit(ast.left)
        right = visit(ast.right)
        if type2check(left, right) != nil
          val = (left.value <= right.value)
          if val
            return @st["true"]
          else
            return @st["false"]
          end
        end
      when NotEqlv then
        left = visit(ast.left)
        right = visit(ast.right)
        if type2check(left, right) != nil
          val = (left.value != right.value)
          if val
            return @st["true"]
          else
            return @st["false"]
          end
        end
      when Eqlv then
        left = visit(ast.left)
        right = visit(ast.right)
        if type2check(left, right) != nil
          val = (left.value == right.value)
          if val
            return @st["true"]
          else
            return @st["false"]
          end
        end
      when Add then
        left = visit(ast.left)
        right = visit(ast.right)
        if type2check(ast.lineno, left, right) != nil
          case left
          when Number then
            return Number.new(ast.lineno, left.value + right.value)
          when StrLiteral then
            return StrLiteral.new(ast.lineno, left.value + right.value)
          end
        else
          return nil
        end
      when Sub then
        left = visit(ast.left)
        right = visit(ast.right)
        if type2check(ast.lineno, left, right) != nil
          return Number.new(ast.lineno, left.value - right.value)
        else
          return nil
        end
      when Mul then
        left = visit(ast.left)
        right = visit(ast.right)
        if type2check(ast.lineno, left, right) != nil
          return Number.new(ast.lineno, left.value * right.value)
        else
          return nil
        end
      when Div then
        left = visit(ast.left)
        right = visit(ast.right)
        if right.value == 0
          puts 'divide by zero'
          return nil
        end
        if type2check(ast.lineno, left, right) != nil
          return Number.new(ast.lineno, left.value / right.value)
        else
          return nil
        end
      when Number then
        return Number.new(ast.lineno, ast.value)
      when StrLiteral then
        return StrLiteral.new(ast.lineno, ast.value)
      when List then
        fields = ast.fields.map { |node| node = visit(node)}
        arr = Array.new
        fields.each { |field| arr.push(field)}
        return arr
      end
    end
    def typecheck(e1, e2, type)
      if (e1.class.superclass.name != type) || (e2.class.superclass.name != type)
        puts "type error"
        return nil
      else
        return e1
      end
    end
    def type2check(lineno, e1, e2)
      if e1.class.name == e2.class.name
        return e1
      else
        puts "Line #{lineno}, type violation"
        return nil
      end
    end
    def printst
      puts @st.inspect
    end
  end
end
