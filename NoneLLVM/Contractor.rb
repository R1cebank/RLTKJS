module JS
  class Contractor
    def initialize
      @st = Hash.new
    end
    def add(ast)
      case ast
      when Expression then visit ast
      when Function, Prototype then visit ast
      else raise 'Attempting to ass an unhandled node type to JIT.'
      end
    end
    def visit(ast)
      case ast
      when Assign then
        right = visit(ast.right)
        if @st.has_key?(ast.name)
          raise 'Variable already defined'
          return nil
        else
          @st[ast.name] = right
          return nil
        end
      when Variable
        if @st.key?(ast.name)
          return @st[ast.name]
        else
          raise "Uninitialized variable '#{node.name}'."
          return nil
        end
      when Write then
        args = ast.arg_names.map{ |node| node = visit(node)}
        str = ""
        args.map { |node|
          if node.value.to_s != "<br />"
            str += node.value.to_s
          else
            str += "\n"
          end
        }
        print str
      when Add
        left = visit(ast.left)
        right = visit(ast.right)
        return Number.new(left.value + right.value)
      when Sub
        left = visit(ast.left)
        right = visit(ast.right)
        return Number.new(left.value - right.value)
      when Mul
        left = visit(ast.left)
        right = visit(ast.right)
        return Number.new(left.value * right.value)
      when Div
        left = visit(ast.left)
        right = visit(ast.right)
        return Number.new(left.value / right.value)
      when Number
        return Number.new(ast.value)
      when StrLiteral
        return StrLiteral.new(ast.value)
      end
    end
    def printst
      puts @st.inspect
    end
  end
end
