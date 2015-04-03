module JS
  class Contractor
    def initialize
      # add a new local map
      @st = Hash.new
      @st["true"] = True.new(true)
      @st["false"] = False.new(false)
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
      when IfStmt then
        cond = visit(ast.cond)
        if cond.value
          ast.ifBlock.map { |stmt| visit(stmt)}
        end
          ast.elseBlock.map {
            |stmt|
            case stmt
            when IfStmt
              visit(stmt)
            end
          }
      when Variable then
        if @st.key?(ast.name)
          return @st[ast.name]
        else
          puts "uninitialized variable"
          return nil
        end
      when ObjVariable then
        obj = visit(Variable.new(ast.name))
        if obj.key?(ast.fname)
          return obj[ast.fname]
        else
          raise "undeclared field"
        end
        puts obj.inspect
      when Object then
        fields = ast.fields.map { |node| node = visit(node)}
        obj = Hash.new
        fields.each { |field| obj[field.name] = field.expr}
        return obj
      when Field then
        return Field.new(ast.name, visit(ast.expr))
      when Write then
        args = ast.arg_names.map{ |node| node = visit(node)}
        str = ""
        args.map { |node|
          if node == nil
            str += "nil"
          elsif node.value.to_s != "<br />"
            str += node.value.to_s
          else
            str += "\n"
          end
        }
        print str
      when Add then
        left = visit(ast.left)
        right = visit(ast.right)
        if type2check(left, right) != nil
          case left
          when Number then
            return Number.new(left.value + right.value)
          when StrLiteral then
            return StrLiteral.new(left.value + right.value)
          end
        else
          return nil
        end
      when Sub then
        left = visit(ast.left)
        right = visit(ast.right)
        if type2check(left, right) != nil
          return Number.new(left.value - right.value)
        else
          return nil
        end
      when Mul then
        left = visit(ast.left)
        right = visit(ast.right)
        if type2check(left, right) != nil
          return Number.new(left.value * right.value)
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
        if type2check(left, right) != nil
          return Number.new(left.value / right.value)
        else
          return nil
        end
      when Number then
        return Number.new(ast.value)
      when StrLiteral then
        return StrLiteral.new(ast.value)
      end
    end
    def type2check(e1, e2)
      if e1.class.name == e2.class.name
        return e1
      else
        puts "type error"
        return nil
      end
    end
    def printst
      puts @st.inspect
    end
  end
end
