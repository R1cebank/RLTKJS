require 'rltk/cg/llvm'
require 'rltk/cg/module'
require 'rltk/cg/execution_engine'
require 'rltk/cg/contractor'

# tells LLVM we are using x86 arch
RLTK::CG::LLVM.init(:X86)

module JS
  class Contractor < RLTK::CG::Contractor
    attr_reader :module

    def initialize
      super

      # ir objects
      @module = RLTK::CG::Module.new('JS JIT')
      @st     = Hash.new

      # execution engine
      @engine = RLTK::CG::JITCompiler.new(@module)

      # pass to
      @module.fpm.add(:InstCombine, :Reassociate, :GVN, :CFGSimplify)
    end

    def add(ast)
      case ast
      when Expression then visit Function.new(Prototype.new('',[]), ast)
      when Function, Prototype then visit ast
      else raise 'Attempting to ass an unhandled node type to JIT.'
      end
    end
    def execute(fun, *args)
      @engine.run_function(fun, *args)
    end
    def optimize(fun)
      @module.fpm.run(fun)
      fun
    end

    on Assign do |node|
      right = visit node.right
      loc =
      if @st.has_key?(node.name)
        puts "good"
        @st[node.name]
      else
        puts "bad"
        @st[node.name] = alloca RLTK::CG::DoubleType, node.name
      end
      store right, loc
    end
    on Binary do |node|
      left = visit node.left
      right = visit node.right
      case node
      when Add then fadd(left, right, 'addtmp')
      when Sub then fadd(left, right, 'addtmp')
      when Mul then fadd(left, right, 'addtmp')
      when Div then fadd(left, right, 'addtmp')
      end
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
      puts "here"
      puts @st
      if @st.key?(node.name)
        @st[node.name]
      else
        raise "Uninitialized variable '#{node.name}'."
      end
    end
    on Number do |node|
      RLTK::CG::Double.new(node.value)
    end
    on Str do |node|
      RLTK::CG::Double.new(1.to_s)
    end
    on Function do |node|

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
					(@st[name] = fun.params[i]).name = name
				end
			end
    end
  end
end
