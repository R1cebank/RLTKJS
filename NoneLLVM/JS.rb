require './Lexer'
require './Parser'
require './Contractor'

jit = JS::Contractor.new

file = File.open(ARGV[0])
contents = file.read

begin
  ast = JS::Parser.parse(JS::Lexer.lex(contents))
  jit.init(ast)
  ast.each do |node|
    jit.pre(node)
  end
  ast.each do |node|
    # puts node.inspect
    jit.add(node)
    if jit.exit()
      break
    end
  end
  # jit.printst()
rescue RLTK::LexingError, RLTK::NotInLanguage
  STDERR.puts 'syntax error'
end
