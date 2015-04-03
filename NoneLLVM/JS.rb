require './Lexer'
require './Parser'
require './Contractor'

jit = JS::Contractor.new

file = File.open(ARGV[0])
contents = file.read

begin
  ast = JS::Parser.parse(JS::Lexer.lex(contents))
  ast.each do |node|
    jit.add(node)
  end
rescue RLTK::LexingError, RLTK::NotInLanguage
  puts 'syntax error'
end
