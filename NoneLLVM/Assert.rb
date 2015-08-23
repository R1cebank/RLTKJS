module JS
  class AssertNode
    @dep = nil
    @name = nil
    @index = nil
    attr_reader :dep, :name, :index
    def initialize(n,i)
      @name = n
      @index = i
      @dep = Array.new
    end
  end
  class Assert
    def initialize
      @paren = nil
      @output = Array.new
      @outList = Array.new
      @varList = Array.new
      @slice = Array.new
      @exit = false
      @gst = Hash.new
      @st = Hash.new
      @func = Hash.new
      @errors = Hash.new
      @ret = nil
      @st["true"] = True.new(0, true)
      @st["false"] = False.new(0, false)
    end
    def getret
      return @ret
    end
    def setgst(g)
      @gst = g
    end
    def setfunc(f)
      @func = f
    end
    def setarg(names, values)
      names.zip(values).each do |name, value|
        @st[name] = visit(value)
      end
    end
    def pre(ast)
      case ast
      when Function then
        @func[ast.name] = ast
      end
    end
    def add(ast)
      case ast
      when Expression then
        return visit(ast)
      when Function
      else raise 'Attempting to ass an unhandled node type to JIT.'
      end
    end
    def exit
      return @exit
    end
    def init(var)
      @varList = var
    end
    def makeSlice(ast, slice)
      if slice == nil
        slice = Array.new
      end
      astSlice = ast.zip(slice).flatten.compact
      @slice.each do |s|
        s.each do |ss|
          if astSlice.include? ss
            astSlice = astSlice.zip(s).flatten.compact
            return astSlice
          end
        end
      end
      @slice.push(astSlice)
      return astSlice
    end
    def print
      @tree.nodes.each do |n|
        puts "==================Node"
        puts n.inspect
      end
    end
    def printSliceEach(n)
    end
    def printSlice
      #puts @outList.inspect
      node = @outList.find {
        |s|
         if(s != nil)
           s.name == @varList[0]
         end
      }
      @outList.each do |n|
        if n != nil
          @output.push(n.index)
        end
      end
      #printSliceEach(node)
      #puts @outList.inspect
      STDERR.puts "Diagnosis Report"
      @output.each do |n|
        STDERR.puts "Line #{n}"
      end
      #puts node.inspect
    end
    def visit(ast)
      if ast == nil
        return nil
      end
      if @exit
        return
      end
      ast.parent = nil
      case ast
      when Assertion then
        @exit = true
        @outList[ast.lineno] = AssertNode.new("assert", ast.lineno)
        return nil
      when Assign then
        #puts ast.inspect
        @outList[ast.lineno] = AssertNode.new(ast.name, ast.lineno)
        if @paren != nil
          @outList[ast.lineno].dep.push(@paren)
        end
        list = visit(ast.right)
        if list != nil
          list.each do |n|
            @outList[ast.lineno].dep.push(n)
          end
        end
      when Update then
        @outList[ast.lineno] = AssertNode.new(ast.name, ast.lineno)
        if @paren != nil
          @outList[ast.lineno].dep.push(@paren)
        end
        list = visit(ast.right)
        if list != nil
          list.each do |n|
            @outList[ast.lineno].dep.push(n)
          end
        end
      when AssignObject then

      when AssignArray then

      when Break then
      when While then
        @paren = "LoopCond"
        @outList[ast.cond.lineno] = AssertNode.new("LoopCond", ast.cond.lineno)
        if @paren != nil
          @outList[ast.cond.lineno].dep.push(@paren)
        end
        list = visit(ast.cond)
        if list != nil
          list.each do |n|
            @outList[ast.cond.lineno].dep.push(n)
          end
        end
        ast.block.map {
          |node|
          visit(node)
        }
        @paren = nil
      when DoWhile then
      when IfStmt then
        @paren = "ifCond"
        @outList[ast.cond.lineno] = AssertNode.new("ifCond", ast.cond.lineno)
        if @paren != nil
          @outList[ast.cond.lineno].dep.push(@paren)
        end
        list = visit(ast.cond)
        if list != nil
          list.each do |n|
            @outList[ast.cond.lineno].dep.push(n)
          end
        end
        ast.ifBlock.map { |stmt| visit(stmt)}
        ast.elseBlock.map { |stmt| visit(stmt) }
        @paren = nil
      when Variable then
        return ast.name
      when ObjVariable then
      when ArrayVariable then
      when Object then
      when Field then
      when Write then
        return nil
      when And then
        node = Array.new
        node.push(visit(ast.left))
        node.push(visit(ast.right))
      when Or then
        node = Array.new
        node.push(visit(ast.left))
        node.push(visit(ast.right))
      when Gt then
        node = Array.new
        node.push(visit(ast.left))
        node.push(visit(ast.right))
      when Less then
        node = Array.new
        node.push(visit(ast.left))
        node.push(visit(ast.right))
      when GtEq then
        node = Array.new
        node.push(visit(ast.left))
        node.push(visit(ast.right))
      when LessEq then
        node = Array.new
        node.push(visit(ast.left))
        node.push(visit(ast.right))
      when NotEqlv then
        node = Array.new
        node.push(visit(ast.left))
        node.push(visit(ast.right))
      when Eqlv then
        node = Array.new
        node.push(visit(ast.left))
        node.push(visit(ast.right))
      when Add then
        node = Array.new
        node.push(visit(ast.left))
        node.push(visit(ast.right))
        return node
      when Sub then
        node = Array.new
        node.push(visit(ast.left))
        node.push(visit(ast.right))
      when Mul then
        node = Array.new
        node.push(visit(ast.left))
        node.push(visit(ast.right))
        return node
      when Div then
        node = Array.new
        node.push(visit(ast.left))
        node.push(visit(ast.right))
      when Number then
      when StrLiteral then
      when List then
      end
    end
  end
end
