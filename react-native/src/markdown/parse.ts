import { Lexer, type Token, type Tokens } from 'marked';

export type { Token, Tokens };

/** Parses markdown into a CommonMark/GFM token tree using `marked`'s lexer. */
export function parseMarkdown(src: string): Token[] {
  return new Lexer({ gfm: true }).lex(src);
}
