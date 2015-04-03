require 'rltk/parser'
require './AST'

module JS
  class Parser < RLTK::Parser
    left  :PLUS,  :SUB
    left  :MUL,   :DIV

    @stmtList = nil

    production(:input, 'program') {
      |prog|
      @stmtList
    }

    production(:program) do
      clause('statement') {
        |stmt|
        @stmtList = Array.new
        @stmtList.push(stmt)
      }
      clause('program statement') {|prog, stmt| @stmtList.push(stmt)}
    end

    production(:statement) do
      clause('statement SEMI')    {|e, _|  e }
      clause('statement ENDL')    {|e, _|  e }
      clause('expression')    {|e|  e }
      clause('VAR ID EQ expression') { |_,name,_,exp| Assign.new(name, exp)}
      clause('DOCW LPAREN args RPAREN') {
        |_, _, args, _|
        Write.new(args)
      }
    end

    list(:args, :expression, :COMMA)

    production(:expression) do
      clause('NUMBER') { |n| Number.new(n.to_i)}
      clause('STRING') { |n| StrLiteral.new(n[1..-2])}
      clause('ID') {|n| Variable.new(n)}

      clause('LPAREN expression RPAREN') {|_,e,_| e}
      clause('expression PLUS expression') {|e1,_,e2| Add.new(e1,e2)}
      clause('expression SUB expression') {|e1,_,e2| Sub.new(e1,e2)}
      clause('expression MUL expression') {|e1,_,e2| Mul.new(e1,e2)}
      clause('expression DIV expression') {|e1,_,e2| Div.new(e1,e2)}
    end
    # list(:args, :expression, :COMMA)
    finalize({:use => 'jsparser.tbl'})
  end
end
