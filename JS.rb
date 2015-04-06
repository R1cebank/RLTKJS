require './Lexer'
require './Parser'
require './Contractor'

#create a JIT
jit = JS::Contractor.new

file = File.open(ARGV[0])
contents = file.read

begin
  ast = JS::Parser.parse(JS::Lexer.lex(contents))
  jit.add(ast)
  jit.finalize()
  jit.dump()
  puts "=> #{jit.execute().to_i()}"
rescue RLTK::LexingError, RLTK::NotInLanguage
  puts 'syntax error'
end
