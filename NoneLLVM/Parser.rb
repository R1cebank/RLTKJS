require 'rltk/parser'
require './AST'

module JS
  class Parser < RLTK::Parser
    left  :PLUS,  :SUB
    left  :MUL,   :DIV
    left  :AND
    left  :OR
    left  :GT,    :LESS,  :GTEQ, :LESSEQ
    left  :EQLV, :NOTEQLV

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
      clause('program statement') {
        |prog, stmt|
        @stmtList.push(stmt)
      }
    end

    production(:statement) do
      #clause('statement SEMI')    {|e, _|  e }
      #clause('statement ENDL')    {|e, _|  e }
      clause('ifstmt') { |e| e  }
      clause('function') { |e| e }
      clause('loop')   { |e| e  }
      clause('VAR ID') { |_,n| Assign.new(pos(0).line_number, n, nil)}
      clause('ID DOT ID EQ expression') { |n,_,fn,_,exp| AssignObject.new(pos(0).line_number, n, fn, exp)}
      clause('VAR ID EQ expression') { |_,name,_,exp| Assign.new(pos(0).line_number, name, exp)}
      clause('ID EQ expression') { |name,_,exp| Update.new(pos(0).line_number, name,exp)}
      clause('ID LBRA NUMBER RBRA EQ expression') {
        |name, _, i, _, _, exp|
        AssignArray.new(pos(0).line_number, name,i,exp)
      }
      clause('DOCW LPAREN args RPAREN') {
        |_, _, args, _|
        Write.new(pos(0).line_number, args)
      }
      clause('expression')    {|e|  e }
    end

    production(:loop) do
      clause('WHILE LPAREN expression RPAREN LCURL block RCURL') {
        |_,_,cond,_,_,block,_|
        While.new(pos(0).line_number, cond, block)
      }
      clause('DO LCURL block RCURL WHILE LPAREN expression RPAREN') {
        |_,_,block,_,_,_,cond,_|
        DoWhile.new(pos(0).line_number, cond, block)
      }
    end
    production(:ifstmt) do
      clause('IF LPAREN expression RPAREN LCURL block RCURL') {
        |_,_,cond,_,_,block,_|
        IfStmt.new(pos(0).line_number, cond, block, Array.new)
      }
      clause('IF LPAREN expression RPAREN LCURL block RCURL ELSE ifstmt') {
        |_,_,cond,_,_,block,_,_,ifstmt|
        IfStmt.new(pos(0).line_number, cond, block, [ifstmt])
      }
      clause('IF LPAREN expression RPAREN LCURL block RCURL ELSE LCURL block RCURL') {
        |_,_,cond,_,_,block,_,_,_,eblock,_|
        IfStmt.new(pos(0).line_number, cond, block, eblock)
      }
    end

    production(:function) do
      clause('FUNCTION ID LPAREN argnames RPAREN LCURL block RCURL') {
        |_,name,_,argnames,_,_,block,_|
        Function.new(pos(0).line_number, name, argnames, block)
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
        block.push(stmt)
      }
    end

    production(:field) do
      clause('ID COLON expression') { |name, _, exp | Field.new(pos(0).line_number, name,exp)}
    end

    list(:argnames, :ID, :COMMA)

    list(:arrayfields, :expression, :COMMA)

    list(:fields, :field, :COMMA)

    list(:args, :expression, :COMMA)

    production(:expression) do
      clause('NUMBER') { |n| Number.new(pos(0).line_number, n)}
      clause('STRING') { |n| StrLiteral.new(pos(0).line_number, n[1..-2])}
      clause('ID') {|n| Variable.new(pos(0).line_number, n)}
      clause('ID LPAREN args RPAREN') {
        |name,_,args,_|
        Call.new(pos(0).line_number, name, args)
      }
      clause('ID LBRA NUMBER RBRA') { |n,_,i,_| ArrayVariable.new(pos(0).line_number, n,i)}
      clause('LBRA arrayfields RBRA') { |_,fields,_| List.new(pos(0).line_number, fields)}
      clause('BREAK') { |_| Break.new(pos(0).line_number)}

      clause('ASSERT LPAREN expression RPAREN') {|_,_,exp,_| Assertion.new(pos(0).line_number, exp)}
      clause('RETURN expression') { |_,e| Return.new(pos(0).line_number, e)}
      clause('ID DOT ID') { |name, _, fname| ObjVariable.new(pos(0).line_number, name, fname)}
      clause('LPAREN expression RPAREN') {|_,e,_| e}
      clause('LCURL fields RCURL') { |_, f, _| Object.new(pos(0).line_number, f)}
      clause('expression PLUS expression') {|e1,_,e2| Add.new(pos(0).line_number, e1,e2)}
      clause('expression SUB expression') {|e1,_,e2| Sub.new(pos(0).line_number, e1,e2)}
      clause('expression MUL expression') {|e1,_,e2| Mul.new(pos(0).line_number, e1,e2)}
      clause('expression DIV expression') {|e1,_,e2| Div.new(pos(0).line_number, e1,e2)}
      clause('expression AND expression') {|e1,_,e2| And.new(pos(0).line_number, e1,e2)}
      clause('expression OR expression')  {|e1,_,e2| Or.new(pos(0).line_number, e1,e2)}
      clause('expression GT expression')  {|e1,_,e2| Gt.new(pos(0).line_number, e1,e2)}
      clause('expression LESS expression')  {|e1,_,e2| Less.new(pos(0).line_number, e1,e2)}
      clause('expression GTEQ expression')  {|e1,_,e2| GtEq.new(pos(0).line_number, e1,e2)}
      clause('expression LESSEQ expression')  {|e1,_,e2| LessEq.new(pos(0).line_number, e1,e2)}
      clause('expression NOTEQLV expression')  {|e1,_,e2| NotEqlv.new(pos(0).line_number, e1,e2)}
      clause('expression EQLV expression')  {|e1,_,e2| Eqlv.new(pos(0).line_number, e1,e2)}
    end
    # list(:args, :expression, :COMMA)
    finalize({:use => 'jsparser.tbl'})
  end
end
