require 'rltk/cg/llvm'
require 'rltk/cg/module'
require 'rltk/cg/execution_engine'
require 'rltk/cg/contractor'

# tells LLVM we are using x86 arch
RLTK::CG::LLVM.init(:X86)
# include supporting library
RLTK::CG::Support.load_library('./stdlib.so')

module JS
  class Contractor < RLTK::CG::Contractor
    attr_reader :module

    def initialize
      super

      # ir objects
      @module = RLTK::CG::Module.new('JS JIT')
      @st     = Hash.new
      @func   = Hash.new

      # execution engine
      @engine = RLTK::CG::JITCompiler.new(@module)

      # pass to
      @module.fpm.add(:InstCombine, :Reassociate, :GVN, :CFGSimplify, :PromoteMemToReg)

      # define supporting library
      @func["ptD"] = @module.functions.add("ptD",
                                            RLTK::CG::NativeIntType,
                                            Array.new(1,
                                            RLTK::CG::DoubleType))
      @func["nl"] = @module.functions.add("nl",
                                            RLTK::CG::NativeIntType,
                                            [])
      # create main func
      @func["main"] = @module.functions.add("main",
                                            RLTK::CG::NativeIntType,
                                            [])
      @st["test"] = @module.globals.add(RLTK::CG::PointerType.new(RLTK::CG::NativeIntType),"test")
      @st["test"].linkage = :weak_any
    end

    def finalize()
      #build(@func["main"].blocks.append()) do
        #ret (visit Number.new(0))
      #end
      @func["main"].tap { @func["main"].verify }
    end

    def add(ast)
      build(@func["main"].blocks.append("entry")) do
        # initialize all global variables
        ast.map { |node| visit node }
        ret (RLTK::CG::NativeInt.new(0))
      end
    end
    def execute()
      optimize(@func["main"])
      @engine.run_function(@func["main"])
    end
    def optimize(fun)
      @module.fpm.run(fun)
      fun
    end
    def dump()
      @func.each do |key, value|
        value.dump()
      end
      @st.each do |key, value|
        puts value.inspect
      end
      @st["test"].dump()

    end
    def dumpo()
      @func.each do |key, value|
        optimize(value).dump()
      end

    end

    on Assign do |node|
      right = visit node.right
      loc =
      if @st.has_key?(node.name)
        @st[node.name]
      else
        @st[node.name] = alloca RLTK::CG::DoubleType, node.name
      end
      store right, loc
      nil
    end
    on Binary do |node|
      left = visit node.left
      right = visit node.right
      case node
      when Add then fadd(left, right, 'addtmp')
      when Sub then fsub(left, right, 'subtmp')
      when Mul then fmul(left, right, 'multmp')
      when Div then fdiv(left, right, 'divtmp')
      end
    end
    on Write do |node|
      visit Call.new(node.lineno, "ptD", node.arg_names)
    end
    on Call do |node|
			callee = @module.functions[node.name]


			if not callee
				raise 'Unknown function referenced.'
			end

			if callee.params.size != node.args.length
				raise "Function #{node.name} expected #{callee.params.size} argument(s) but was called with #{node.args.length}."
			end

			args = node.args.map { |arg| visit arg }
			call callee, *args.push('calltmp')
		end

    on Variable do |node|
      if @st.key?(node.name)
        self.load @st[node.name], node.name
      else
        raise "Uninitialized variable '#{node.name}'."
      end
    end
    on Number do |node|
      RLTK::CG::Double.new(node.value.to_f)
    end
    on Function do |node|

      puts node.inspect

      # Reset the symbol table.
      @st.clear

			# Translate the function's prototype.
			fun = visit node.proto

			# Create a new basic block to insert into, allocate space for
			# the arguments, store their values, translate the expression,
			# and set its value as the return value.
			build(fun.blocks.append('entry')) do
				fun.params.each do |param|
					@st[param.name] = alloca RLTK::CG::DoubleType, param.name
					store param, @st[param.name]
				end

				ret (visit node.body)
			end

			# Verify the function and return it.
			fun.tap { fun.verify }
    end
    on Prototype do |node|
      if fun = @module.functions[node.name]
				if fun.blocks.size != 0
					raise "Redefinition of function #{node.name}."
				elsif fun.params.size != node.arg_names.length
					raise "Redefinition of function #{node.name} with different number of arguments."
				end
			else
				fun = @module.functions.add(node.name, RLTK::CG::DoubleType, Array.new(node.arg_names.length, RLTK::CG::DoubleType))
      end

			# Name each of the function paramaters.
			fun.tap do
				node.arg_names.each_with_index do |name, i|
					fun.params[i].name = name
				end
			end
    end
    def printst
      puts @st.inspect
    end
  end
end
