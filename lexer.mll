(* Analyseur lexical pour miniC++ *)

{
  open Lexing
  open Parser
   
  exception Lexing_error of string

  (* tables des mots-cl�s *)
  let kwd_tbl = Hashtbl.create 17
    
  let _ =
    List.iter (fun (s,t) -> Hashtbl.add kwd_tbl s t)
      [
	"class", CLASS; "else", ELSE; "false", FALSE;
	"for", FOR; "if", IF; "int", INT; "new", NEW;
	"NULL", NULL; "public", PUBLIC; "return", RETURN;
	"this", THIS; "true", TRUE; "virtual", VIRTUAL;
	"void", VOID; "while", WHILE
      ]
      

  (* d�termine si on a un identifieur ou un mot cl� *)
  let id_or_kwd s = 
      try Hashtbl.find kwd_tbl s with 
	Not_found -> IDENT s

  (* va � la ligne suivante en incr�mentant la r�f�rence de ligne *)
  let newline lexbuf =
    let pos = lexbuf.lex_curr_p in
    lexbuf.lex_curr_p <- 
      { pos with pos_lnum = pos.pos_lnum + 1; pos_bol = pos.pos_cnum }

}

let digit = ['0'-'9']
let alpha = ['a'-'z' 'A'-'Z']
let ident = (alpha | '_') (alpha | '_' | digit)*
let tident = (alpha | '_') (alpha | '_' | digit)*
let octal_digit = ['0'-'7']
let hexa_digit = ['0'-'9' 'a'-'f' 'A'-'F']
let integer = '0' | ['1'-'9'] digit* | '0' octal_digit+ | "0x" hexa_digit+
(* Il faut enlever le '\' et le '"' *)
let carac = ['\032'-'\033' '\035'-'\038' '\040'-'\091'
  '\093'-'\127'] | "\\\\" | "\\\"" | "\\\'" 
  |"\\x" hexa_digit hexa_digit
  |"\\n" |"\\t"
let string = '\"' carac* '\"'
let space = [' ' '\t']

rule token = parse
  | "#include <iostream>" { IOSTREAM }
  | "std::cout" { COUT }
  | "\n"    { newline lexbuf; token lexbuf }
  | space+  { token lexbuf }
  | string as s {STRING (String.sub s 1 (String.length s - 1))}
  | ident as id { id_or_kwd id }
  | '='     { EQ }
  | "||"    { OR }
  | "&&"    { AND }
  | "=="    { DEQ }
  | "!="    { NEQ }
  | '<'     { LT }
  | "<="    { LE }
  | '>'     { GT }
  | ">="    { GE }
  | "<<"    { DLT }
(* Il faut int�grer le support des op�rateurs unaires '+', '-' et '*' *)
  | '+'     { PLUS }
  | '-'     { MINUS }
  | '*'     { STAR }
  | '/'     { DIV }
  | '%'     { MOD }
  | '!'     { EXCL }
  | "++"    { DPLUS }
  | "--"    { DMINUS }
  | '('     { LPAREN }
  | ')'     { RPAREN }
  | '{'     { LBRACE }
  | '}'     { RBRACE }
  | '.'     { DOT }
  | "->"    { POINTER }
  | '&'     { AMP }
  | ','     { COMMA }
  | ':'     { COLON }
  | "::"    { DCOLON }
  | ";"     { SEMICOLON }
  | "/*"    { comment lexbuf }
  | "//"    { newline lexbuf; token lexbuf }
  | integer as s { CST (int_of_string s) }
  | eof     { EOF }
  | _ as c  { raise (Lexing_error ("illegal character: " ^ String.make 1 c)) }

and comment = parse
  | "*/"    { token lexbuf }
  | _       { comment lexbuf }
  | eof     { raise (Lexing_error ("unterminated comment")) }
