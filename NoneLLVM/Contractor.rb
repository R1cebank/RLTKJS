module JS
  class Contractor
    def initialize
      @st = Hash.new
      @func = Hash.new
      @errors = Hash.new
      @st["true"] = True.new(0, true)
      @st["false"] = False.new(0, false)
    end
    def pre(ast)
      case ast
      when Function then
        @func[ast.name] = ast
      end
    end
    def add(ast)
      case ast
      when Expression then visit ast
      when Function
      else raise 'Attempting to ass an unhandled node type to JIT.'
      end
    end
    def visit(ast)
      if ast == nil
        return nil
      end
      case ast
      when Call then
        func = @func[ast.name]
        if func != nil
          func.block.map {
            |stmt|
            visit stmt
          }
        end
      when Assign then
        right = visit(ast.right)
        if @st.has_key?(ast.name)
          @st[ast.name] = right
          return nil
        else
          @st[ast.name] = right
          return nil
        end
      when Update then
        right = visit(ast.right)
        if @st.has_key?(ast.name)
          @st[ast.name] = right
          return nil
        else
          emitError(ast.lineno, "Line #{ast.lineno}, #{ast.name} undeclared")
          return nil
        end
      when AssignObject then
        right = visit(ast.right)
        if @st.has_key?(ast.name)
          @st[ast.name][ast.fname] = right
          return nil
        else
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
      when Break then
        return ast
      when While then
        runStat = nil
        cond = visit(ast.cond)
        case cond
        when Undef
          emitError(ast.lineno, "Line #{cond.lineno}, condition unknown")
          return
        else
          if cond.value
            ast.block.map {
              |stmt|
              status = visit(stmt)
              if status.kind_of?(Array)
                if status.any?
                  if status.include?(Break.new())
                    runStat = Break.new()
                    break
                  end
                end
              end
            }
            if !runStat.kind_of?(Break)
              visit(ast)
            end
          end
        end
      when DoWhile then
        runStat = nil
        ast.block.map {
          |stmt|
          status = visit(stmt)
          if status.kind_of?(Array)
            if status.any?
              if status.include?(Break.new())
                runStat = Break.new()
                break
              end
            end
          end
        }
        cond = visit(ast.cond)
        case cond
        when Undef
          emitError(ast.lineno, "Line #{cond.lineno}, condition unknown")
          return
        else
          if cond.value
            if !runStat.kind_of?(Break)
              visit(ast)
            end
          end
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
          if !@func.key?(ast.name)
            emitError(ast.lineno, "Line #{ast.lineno}, #{ast.name} has no value")
            return Undef.new(ast.lineno, "undefined")
          end
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
            emitError(ast.lineno, "Line #{ast.lineno}, field #{ast.fname} is not found in object #{ast.name}")
            return Undef.new(ast.lineno, "undefined")
          end
        else
          emitError(ast.lineno, "Line #{ast.lineno}, #{ast.name} is not an object")
          return Undef.new(ast.lineno, "undefined")
        end
      when ArrayVariable then
        arr = visit(Variable.new(ast.lineno, ast.name))
        if (arr[ast.index] == nil)
          return Undef.new(ast.lineno, "undefined")
        else
          return arr[ast.index]
        end
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
          return Undef.new(ast.lineno, "undefined")
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
          return Undef.new(ast.lineno, "undefined")
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
        else
          return Undef.new(ast.lineno, "undefined")
        end
      when Less then
        left = visit(ast.left)
        right = visit(ast.right)
        if type2check(ast.lineno, left, right) != nil
          val = (left.value < right.value)
          if val
            return @st["true"]
          else
            return @st["false"]
          end
        else
          return Undef.new(ast.lineno, "undefined")
        end
      when GtEq then
        left = visit(ast.left)
        right = visit(ast.right)
        if type2check(ast.lineno, left, right) != nil
          val = (left.value >= right.value)
          if val
            return @st["true"]
          else
            return @st["false"]
          end
        else
          return Undef.new(ast.lineno, "undefined")
        end
      when LessEq then
        left = visit(ast.left)
        right = visit(ast.right)
        if type2check(ast.lineno, left, right) != nil
          val = (left.value <= right.value)
          if val
            return @st["true"]
          else
            return @st["false"]
          end
        else
          return Undef.new(ast.lineno, "undefined")
        end
      when NotEqlv then
        left = visit(ast.left)
        right = visit(ast.right)
        if type2check(ast.lineno, left, right) != nil
          val = (left.value != right.value)
          if val
            return @st["true"]
          else
            return @st["false"]
          end
        else
          return Undef.new(ast.lineno, "undefined")
        end
      when Eqlv then
        left = visit(ast.left)
        right = visit(ast.right)
        if type2check(ast.lineno, left, right) != nil
          val = (left.value == right.value)
          if val
            return @st["true"]
          else
            return @st["false"]
          end
        else
          return Undef.new(ast.lineno, "undefined")
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
          return Undef.new(ast.lineno, "undefined")
        end
      when Sub then
        left = visit(ast.left)
        right = visit(ast.right)
        if type2check(ast.lineno, left, right) != nil
          return Number.new(ast.lineno, left.value - right.value)
        else
          return Undef.new(ast.lineno, "undefined")
        end
      when Mul then
        left = visit(ast.left)
        right = visit(ast.right)
        if type2check(ast.lineno, left, right) != nil
          return Number.new(ast.lineno, left.value * right.value)
        else
          return Undef.new(ast.lineno, "undefined")
        end
      when Div then
        left = visit(ast.left)
        right = visit(ast.right)
        if right.value == 0
          puts 'divide by zero'
          return Undef.new(ast.lineno, "undefined")
        end
        if type2check(ast.lineno, left, right) != nil
          return Number.new(ast.lineno, left.value / right.value)
        else
          return Undef.new(ast.lineno, "undefined")
        end
        return Number.new(ast.lineno, ast.value)
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
        emitError(e1.lineno, "Line #{e1.lineno}, type violation")
        return nil
      else
        return e1
      end
    end
    def type2check(lineno, e1, e2)
      if e1.class.name == e2.class.name
        return e1
      else
        emitError(e1.lineno, "Line #{e1.lineno}, type violation")
        return nil
      end
    end
    def emitError(lineno, error)
      if @errors.has_key?(lineno)
        return false
      else
        @errors[lineno] = error
        puts error
        return true
      end
    end
    def printfunc
      puts @func.inspect
    end
    def printst
      puts @st.inspect
    end
  end
end
