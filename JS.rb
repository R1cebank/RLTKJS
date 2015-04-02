require './Lexer'
require './Parser'
require './Contractor'

#create a JIT
jit = JS::Contractor.new

file = File.open(ARGV[0])
contents = file.read

begin
  ast = JS::Parser.parse(JS::Lexer.lex(contents))
  ast.each do |node|
    ir = jit.add(node)
    ir.dump()
    puts jit.execute(ir).to_f(RLTK::CG::DoubleType)
  end
rescue RLTK::LexingError, RLTK::NotInLanguage
  puts 'syntax error'
end
