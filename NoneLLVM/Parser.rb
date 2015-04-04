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
      #clause('statement SEMI')    {|e, _|  e }
      #clause('statement ENDL')    {|e, _|  e }
      clause('ifstmt') { |e| e  }
      clause('VAR ID EQ expression') { |_,name,_,exp| Assign.new(name, exp)}
      clause('ID EQ expression') { |name,_,exp| Assign.new(name,exp)}
      clause('ID LBRA NUMBER RBRA EQ expression') {
        |name, _, i, _, _, exp|
        AssignArray.new(name,i,exp)
      }
      clause('DOCW LPAREN args RPAREN') {
        |_, _, args, _|
        Write.new(args)
      }
      clause('expression')    {|e|  e }
    end

    production(:ifstmt) do
      clause('IF LPAREN expression RPAREN LCURL block RCURL') {
        |_,_,cond,_,_,block,_|
        IfStmt.new(cond, block, Array.new)
      }
      clause('IF LPAREN expression RPAREN LCURL block RCURL ELSE ifstmt') {
        |_,_,cond,_,_,block,_,_,ifstmt|
        IfStmt.new(cond, block, [ifstmt])
      }
      clause('IF LPAREN expression RPAREN LCURL block RCURL ELSE LCURL block RCURL') {
        |_,_,cond,_,_,block,_,_,_,eblock,_|
        IfStmt.new(cond, block, eblock)
      }
    end

    production(:block) do
      clause('statement') {
        |stmt|
        stmtList = Array.new
        stmtList.push(stmt)
      }
      clause('block statement') {
        |block, stmt|
        puts "block stmt"
        block.push(stmt)
      }
    end

    production(:field) do
      clause('ID COLON expression') { |name, _, exp | Field.new(name,exp)}
    end

    list(:arrayfields, :expression, :COMMA)

    list(:fields, :field, :COMMA)

    list(:args, :expression, :COMMA)

    production(:expression) do
      clause('NUMBER') { |n| Number.new(n)}
      clause('STRING') { |n| StrLiteral.new(n[1..-2])}
      clause('ID') {|n| Variable.new(n)}
      clause('ID LBRA NUMBER RBRA') { |n,_,i,_| ArrayVariable.new(n,i)}
      clause('LBRA arrayfields RBRA') { |_,fields,_| List.new(fields)}

      clause('ID DOT ID') { |name, _, fname| ObjVariable.new(name, fname)}
      clause('LPAREN expression RPAREN') {|_,e,_| e}
      clause('LCURL fields RCURL') { |_, f, _| Object.new(f)}
      clause('expression PLUS expression') {|e1,_,e2| Add.new(e1,e2)}
      clause('expression SUB expression') {|e1,_,e2| Sub.new(e1,e2)}
      clause('expression MUL expression') {|e1,_,e2| Mul.new(e1,e2)}
      clause('expression DIV expression') {|e1,_,e2| Div.new(e1,e2)}
      clause('expression AND expression') {|e1,_,e2| And.new(e1,e2)}
      clause('expression OR expression')  {|e1,_,e2| Or.new(e1,e2)}
      clause('expression GT expression')  {|e1,_,e2| Gt.new(e1,e2)}
      clause('expression LESS expression')  {|e1,_,e2| Less.new(e1,e2)}
      clause('expression GTEQ expression')  {|e1,_,e2| GtEq.new(e1,e2)}
      clause('expression LESSEQ expression')  {|e1,_,e2| LessEQ.new(e1,e2)}
      clause('expression NOTEQLV expression')  {|e1,_,e2| NotEqlv.new(e1,e2)}
      clause('expression EQLV expression')  {|e1,_,e2| Eqlv.new(e1,e2)}
    end
    # list(:args, :expression, :COMMA)
    finalize({:use => 'jsparser.tbl'})
  end
end
