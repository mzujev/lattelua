local debug_grammar = false
local lpeg = require("lpeg")
lpeg.setmaxstack(10000)
local err_msg = "Failed to parse:%s\n [%d] >>    %s"
local Stack
Stack = require("lattelua.data").Stack
local lua_keywords = require("lattelua.data").lua_keywords
local trim, pos_to_line, get_line
do
  local _obj_0 = require("lattelua.util")
  trim, pos_to_line, get_line = _obj_0.trim, _obj_0.pos_to_line, _obj_0.get_line
end
local unpack
unpack = require("lattelua.util").unpack
local wrap_env
wrap_env = require("lattelua.parse.env").wrap_env
local R, S, V, P, C, Ct, Cmt, Cg, Cb, Cc
R, S, V, P, C, Ct, Cmt, Cg, Cb, Cc = lpeg.R, lpeg.S, lpeg.V, lpeg.P, lpeg.C, lpeg.Ct, lpeg.Cmt, lpeg.Cg, lpeg.Cb, lpeg.Cc
local White, Break, Stop, Comment, Space, SomeSpace, SpaceBreak, EmptyLine, AlphaNum, Num, Shebang, L, _Name
do
  local _obj_0 = require("lattelua.parse.literals")
  White, Break, Stop, Comment, Space, SomeSpace, SpaceBreak, EmptyLine, AlphaNum, Num, Shebang, L, _Name = _obj_0.White, _obj_0.Break, _obj_0.Stop, _obj_0.Comment, _obj_0.Space, _obj_0.SomeSpace, _obj_0.SpaceBreak, _obj_0.EmptyLine, _obj_0.AlphaNum, _obj_0.Num, _obj_0.Shebang, _obj_0.L, _obj_0.Name
end
local SpaceName = Space * _Name
Num = Space * (Num / function(v)
  return {
    "number",
    v
  }
end)
local Indent, Cut, ensure, extract_line, mark, pos, flatten_or_mark, is_assignable, check_assignable, format_assign, format_single_assign, sym, symx, simple_string, wrap_func_arg, join_chain, wrap_decorator, check_lua_string, self_assign, got
do
  local _obj_0 = require("lattelua.parse.util")
  Indent, Cut, ensure, extract_line, mark, pos, flatten_or_mark, is_assignable, check_assignable, format_assign, format_single_assign, sym, symx, simple_string, wrap_func_arg, join_chain, wrap_decorator, check_lua_string, self_assign, got = _obj_0.Indent, _obj_0.Cut, _obj_0.ensure, _obj_0.extract_line, _obj_0.mark, _obj_0.pos, _obj_0.flatten_or_mark, _obj_0.is_assignable, _obj_0.check_assignable, _obj_0.format_assign, _obj_0.format_single_assign, _obj_0.sym, _obj_0.symx, _obj_0.simple_string, _obj_0.wrap_func_arg, _obj_0.join_chain, _obj_0.wrap_decorator, _obj_0.check_lua_string, _obj_0.self_assign, _obj_0.got
end
local build_grammar = wrap_env(debug_grammar, function(root)
  local _indent = Stack(0)
  local _do_stack = Stack(0)
  local state = {
    last_pos = 0
  }
  local check_line
  check_line = function(str, pos, indent)
    state.last_pos = pos
    return true
  end
  local check_do
  check_do = function(str, pos, do_node)
    local top = _do_stack:top()
    if top == nil or top then
      return true, do_node
    end
    return false
  end
  local keywords = { }
  local key
  key = function(chars)
    keywords[chars] = true
    return Space * chars * -AlphaNum
  end
  local op
  op = function(chars)
    local patt = Space * C(chars)
    if chars:match("^%w*$") then
      keywords[chars] = true
      patt = patt * -AlphaNum
    end
    return patt
  end
  local Name = Cmt(SpaceName, function(str, pos, name)
    if keywords[name] then
      return false
    end
    return true
  end) / trim
  local SelfName = Space * "@" * ("@" * (_Name / mark("self_class") + Cc("self.__class")) + _Name / mark("self") + Cc("self"))
  local KeyName = SelfName + Space * _Name / mark("key_literal")
  local VarArg = Space * P("...") / trim
  local g = P({
    root or File,
    File = Shebang ^ -1 * (Block + Ct("")),
    Block = Ct(Line * (Break ^ 1 * Line) ^ 0),
    CheckLine = Cmt(Indent, check_line),
    Line = (CheckLine * Statement + Space * L(Stop)),
    Statement = pos(Import + While + With + For + ForEach + Switch + Return + Local + Export + BreakLoop + Ct(ExpList) * (Update + Assign) ^ -1 / format_assign) * Space * ((key("if") * Exp * (key("else") * Exp) ^ -1 * Space / mark("if") + key("unless") * Exp / mark("unless") + CompInner / mark("comprehension")) * Space) ^ -1 / wrap_decorator,
    Body = Space ^ -1 * Break ^ -1 * EmptyLine ^ 0 * Block + Ct(Statement),
    Local = key("local") * ((op("*") + op("^")) / mark("declare_glob") + Ct(NameList) / mark("declare_with_shadows")),
    Import = key("import") * Ct(ImportNameList) * SpaceBreak ^ 0 * key("from") * Exp / mark("import"),
    ImportName = (sym("::") * Ct(Cc("colon") * Name) + Name),
    ImportNameList = SpaceBreak ^ 0 * ImportName * ((SpaceBreak ^ 1 + sym(",") * SpaceBreak ^ 0) * ImportName) ^ 0,
    BreakLoop = Ct(key("break") / trim) + Ct(key("continue") / trim),
    Return = key("return") * (ExpListLow / mark("explist") + C("")) / mark("return"),
    WithExp = Ct(ExpList) * Assign ^ -1 / format_assign,
    With = key("with") * ensure(WithExp, P(true)) * sym("{") * Body * White * sym("}") / mark("with"),
    Switch = key("switch") * ensure(Exp, P(true)) * sym("{") * Space ^ -1 * Break * SwitchBlock * White * sym("}") / mark("switch"),
    SwitchBlock = EmptyLine ^ 0 * Ct(SwitchCase * (Break ^ 1 * SwitchCase) ^ 0 * (Break ^ 1 * SwitchElse) ^ -1),
    SwitchCase = key("case") * Ct(ExpList) * Body / mark("case"),
    SwitchElse = key("else") * Body / mark("else"),
    IfCond = Exp * Assign ^ -1 / format_single_assign,
    IfElse = (Break * EmptyLine ^ 0 * CheckLine) ^ -1 * sym("}") * key("else") * sym("{") * Body / mark("else"),
    IfElseIf = (Break * EmptyLine ^ 0 * CheckLine) ^ -1 * sym("}") * key("elseif") * pos(IfCond) * sym("{") * Body / mark("elseif"),
    If = key("if") * IfCond * sym("{") * Body * IfElseIf ^ 0 * IfElse ^ -1 * White * sym("}") / mark("if"),
    Unless = key("unless") * IfCond * sym("{") * Body * IfElseIf ^ 0 * IfElse ^ -1 * White * sym("}") / mark("unless"),
    While = key("while") * ensure(Exp, P(true)) * sym("{") * Body * White * sym("}") / mark("while"),
    For = key("for") * ensure(Name * sym("=") * Ct(Exp * sym(",") * Exp * (sym(",") * Exp) ^ -1), P(true)) * sym("{") * Body * White * sym("}") / mark("for"),
    ForEach = key("for") * Ct(AssignableNameList) * key("in") * ensure(Ct(sym("*") * Exp / mark("unpack") + ExpList), P(true)) * sym("{") * Body * White * sym("}") / mark("foreach"),
    BracesContext = sym("{") * (Body - TableBlock) * White * sym("}"),
    Do = key("do") * White * sym("{") * Body * White * sym("}") / mark("do"),
    Comprehension = sym("[") * Exp * CompInner * sym("]") / mark("comprehension"),
    TblComprehension = sym("{") * Ct(Exp * (sym(",") * Exp) ^ -1) * CompInner * sym("}") / mark("tblcomprehension"),
    CompInner = Ct((CompForEach + CompFor) * CompClause ^ 0),
    CompForEach = key("for") * Ct(AssignableNameList) * key("in") * (sym("*") * Exp / mark("unpack") + Exp) / mark("foreach"),
    CompFor = key("for" * Name * sym("=") * Ct(Exp * sym(",") * Exp * (sym(",") * Exp) ^ -1) / mark("for")),
    CompClause = CompFor + CompForEach + key("when") * Exp / mark("when"),
    Assign = sym("=") * (Ct(With + If + Switch) + Ct(TableBlock + ExpListLow)) / mark("assign"),
    Update = ((sym("..=") + sym("+=") + sym("-=") + sym("*=") + sym("/=") + sym("%=") + sym("or=") + sym("and=") + sym("&=") + sym("|=") + sym(">>=") + sym("<<=")) / trim) * Exp / mark("update"),
    CharOperators = Space * C(S("+-*/%^><|&")),
    WordOperators = op("or") + op("and") + op("<=") + op(">=") + op("~=") + op("!=") + op("==") + op("..") + op("<<") + op(">>") + op("//"),
    BinaryOperator = (WordOperators + CharOperators) * SpaceBreak ^ 0,
    Assignable = Cmt(Chain, check_assignable) + Name + SelfName,
    Exp = Ct(Value * (BinaryOperator * Value) ^ 0) / flatten_or_mark("exp"),
    SimpleValue = If + Unless + Switch + With + ClassDecl + ForEach + For + While + Cmt(Do, check_do) + sym("-") * -SomeSpace * Exp / mark("minus") + sym("#") * Exp / mark("length") + sym("~") * Exp / mark("bitnot") + key("not") * Exp / mark("not") + TblComprehension + TableLit + Comprehension + FunLit + Num,
    ChainValue = (Chain + Callable) * Ct(InvokeArgs ^ -1) / join_chain,
    Value = pos(SimpleValue + Ct(KeyValueList) / mark("table") + ChainValue + String),
    SliceValue = Exp,
    String = Space * DoubleString + Space * SingleString + LuaString,
    SingleString = simple_string("'"),
    DoubleString = simple_string('"', true),
    LuaString = Cg(LuaStringOpen, "string_open") * Cb("string_open") * Break ^ -1 * C((1 - Cmt(C(LuaStringClose) * Cb("string_open"), check_lua_string)) ^ 0) * LuaStringClose / mark("string"),
    LuaStringOpen = sym("[") * P("=") ^ 0 * "[" / trim,
    LuaStringClose = "]" * P("=") ^ 0 * "]",
    Callable = pos(Name / mark("ref")) + SelfName + VarArg + Parens / mark("parens"),
    Parens = sym("(") * SpaceBreak ^ 0 * Exp * SpaceBreak ^ 0 * sym(")"),
    FnArgs = symx("(") * SpaceBreak ^ 0 * Ct(FnArgsExpList ^ -1) * SpaceBreak ^ 0 * sym(")") + sym("!") * -P("=") * Ct(""),
    FnArgsExpList = Exp * ((Break + sym(",")) * White * Exp) ^ 0,
    Chain = (Callable + String + -S(".::")) * ChainItems / mark("chain") + Space * (DotChainItem * ChainItems ^ -1 + ColonChain) / mark("chain"),
    ChainItems = ChainItem ^ 1 * ColonChain ^ -1 + ColonChain,
    ChainItem = Invoke + DotChainItem + Slice + symx("[") * Exp / mark("index") * sym("]"),
    DotChainItem = symx(".") * _Name / mark("dot"),
    ColonChainItem = sym(":") * P(":") * _Name / mark("colon"),
    ColonChain = ColonChainItem * (Invoke * ChainItems ^ -1) ^ -1,
    Slice = symx("[") * (SliceValue + Cc(1)) * sym(",") * (SliceValue + Cc("")) * (sym(",") * SliceValue) ^ -1 * sym("]") / mark("slice"),
    Invoke = FnArgs / mark("call") + SingleString / wrap_func_arg + DoubleString / wrap_func_arg + L(P("[")) * LuaString / wrap_func_arg,
    TableValue = KeyValue + Ct(Exp),
    TableLit = sym("{") * Ct(TableValueList ^ -1 * sym(",") ^ -1 * (SpaceBreak * TableLitLine * (sym(",") ^ -1 * SpaceBreak * TableLitLine) ^ 0 * sym(",") ^ -1) ^ -1) * White * sym("}") / mark("table"),
    TableValueList = TableValue * (sym(",") * TableValue) ^ 0,
    TableLitLine = (TableValueList + Cut) + Space,
    TableBlockInner = Ct(KeyValueLine * (SpaceBreak ^ 1 * KeyValueLine) ^ 0),
    TableBlock = SpaceBreak ^ 1 * ensure(TableBlockInner, P(true)) / mark("table"),
    ClassDecl = key("class") * -P(":") * (Assignable + Cc(nil)) * (key("extends") * ensure(Name, P(true)) + C("")) ^ -1 * sym("{") * (ClassBlock + Ct("")) * White * sym("}") / mark("class"),
    ClassBlock = Space ^ -1 * Break ^ -1 * EmptyLine ^ 0 * Ct(ClassLine * (SpaceBreak ^ 1 * ClassLine) ^ 0),
    ClassLine = CheckLine * ((KeyValueList / mark("props") + Statement / mark("stm") + Exp / mark("stm")) * sym(",") ^ -1),
    Export = key("export") * (Cc("class") * ClassDecl + op("*") + op("^") + Ct(NameList) * (sym("=") * Ct(ExpListLow)) ^ -1) / mark("export"),
    KeyValue = (sym(":") * -P(":") * -SomeSpace * Name * lpeg.Cp()) / self_assign + Ct((KeyName + sym("[") * Exp * sym("]") + Space * DoubleString + Space * SingleString) * symx(":") * -P(":") * (Exp + TableBlock + SpaceBreak ^ 1 * Exp)),
    KeyValueList = KeyValue * (sym(",") * KeyValue) ^ 0,
    KeyValueLine = CheckLine * KeyValueList * sym(",") ^ -1,
    FnArgsDef = sym("(") * White * Ct(FnArgDefList ^ -1) * (key("using") * Ct(NameList + Space * "nil") + Ct("")) * White * sym(")") + Ct("") * Ct(""),
    FnArgDefList = FnArgDef * ((sym(",") + Break) * White * FnArgDef) ^ 0 * ((sym(",") + Break) * White * Ct(VarArg)) ^ 0 + Ct(VarArg),
    FnArgDef = Ct((Name + SelfName) * (sym("=") * Exp) ^ -1),
    FunLit = FnArgsDef * (sym("->") * Cc("slim") + sym("=>") * Cc("fat")) * White * sym("{") * (Body + Ct("")) * White * sym("}") / mark("fndef"),
    NameList = Name * (sym(",") * Name) ^ 0,
    NameOrDestructure = Name + TableLit,
    AssignableNameList = NameOrDestructure * (sym(",") * NameOrDestructure) ^ 0,
    ExpList = Exp * (sym(",") * Exp) ^ 0,
    ExpListLow = Exp * ((sym(",") + sym(";")) * Exp) ^ 0,
    InvokeArgs =  Cmt(#BracesContext, function(str, pos)
      local cause = true
      local line = str:sub(pos):gmatch("([^\n\r]*)")()

      if line then
        local ok = line:gsub("%b{}", function(tbl)

          tbl = tbl:gsub('["\']?(%w*)["\']?(:)', function(w, c)

            if lua_keywords[w] then
              w = ("['%s']"):format(w)
            end

            return ('%s ='):format(w) 
          end)

          local code = loadstring(
            (
              [[
                local print = function()
                  return
                end
                local t = %s

                if type(t) == "table" then
                  return true
                end
                error()
              ]]
            ):format(tbl)
          )

          if (pcall(code)) then
            cause = false
          end
        end)
      end

      return cause
    end) + -P("-") * (ExpList * (sym(",") * (TableBlock + SpaceBreak * ArgBlock * TableBlock ^ -1) + TableBlock) ^ -1 + TableBlock),
    ArgBlock = ArgLine * (sym(",") * SpaceBreak * ArgLine) ^ 0,
    ArgLine = CheckLine * ExpList
  })
  return g, state
end)
local file_parser
file_parser = function()
  local g, state = build_grammar()
  local file_grammar = White * g * White * -1
  return {
    match = function(self, str)
      local tree
      local _, err = xpcall((function()
        tree = file_grammar:match(str)
      end), function(err)
        return debug.traceback(err, 2)
      end)
      if type(err) == "string" then
        return nil, err
      end
      if not (tree) then
        local msg
        local err_pos = state.last_pos
        if err then
          local node
          node, msg = unpack(err)
          if msg then
            msg = " " .. msg
          end
          err_pos = node[-1]
        end
        local line_no = pos_to_line(str, err_pos)
        local line_str = get_line(str, line_no) or ""
        return nil, err_msg:format(msg or "", line_no-2, trim(line_str))
      end
      return tree
    end
  }
end
local preprocess
preprocess = function(str)
  -- strings
  local DQ = P('"') * (1 - P('"')) ^ 0 * P('"')
  local SQ = P("'") * (1 - P("'")) ^ 0 * P("'")
  local LS = P("[[") * (1 - P("]]")) ^ 0 * P("]]")
  -- targets
  local SEMICOLON = P(";") / "\n"
  local TRY = P("try->") / "try ->" + P("try") * White * P("{") / "try -> {"
  local CATCH = P("}") * White * P("catch:") * White * P("=>") / "}, catch: =>" + P("}") * White * P("catch") * White * P("{") / "}, catch: => {"
  local FINALLY = P("}") * White * P("finally:") * White * P("=>") / "}, finally: =>" + P("}") * White * P("finally") * White * P("{") / "}, finally: => {"
  -- any
  local ANY = P(1)
  local Preprocess = lpeg.Cs((C(DQ + SQ + LS + Comment) + SEMICOLON + TRY + CATCH + FINALLY + C(ANY)) ^ 0)

  return Preprocess:match(str)
end
return {
  extract_line = extract_line,
  build_grammar = build_grammar,
  lexer = function(str)
    return file_parser():match(preprocess(str))
  end
}
