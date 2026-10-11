// Pure text -> edit computations, kept free of the vscode API so they can be
// unit-tested with plain node. Each function returns
// { start, end, text, cursor }: replace text[start,end) with `text`, then put
// the cursor at absolute offset `cursor` in the *new* document.

const HEADER = /^\s*(%\s*)?\\(date|author|title|taxon|meta|tag)\b/;

// Find every `\ul{...}` as {open, close} offsets of its braces. Skips escaped
// characters, `%` line comments and verbatim regions.
function scanUls(text) {
  const spans = [];
  const stack = [];
  let i = 0;
  while (i < text.length) {
    const c = text[i];
    if (c === "\\") {
      if (text.startsWith("\\startverb", i)) {
        const e = text.indexOf("\\stopverb", i);
        i = e < 0 ? text.length : e + "\\stopverb".length;
        continue;
      }
      const verb = /^\\verb<\|/.exec(text.slice(i, i + 7));
      if (verb) {
        const e = text.indexOf("|>", i + 7);
        i = e < 0 ? text.length : e + 2;
        continue;
      }
      if (text.startsWith("\\ul{", i)) {
        stack.push({ ul: true, open: i + 3 });
        i += 4;
        continue;
      }
      i += 2; // escaped char (\{ \} \\ \%) or command name start
      continue;
    }
    if (c === "%") {
      const e = text.indexOf("\n", i);
      i = e < 0 ? text.length : e;
      continue;
    }
    if (c === "{") stack.push({ ul: false, open: i });
    else if (c === "}") {
      const top = stack.pop();
      if (top && top.ul) spans.push({ open: top.open, close: i });
    }
    i++;
  }
  return spans;
}

function lineStart(text, off) {
  return text.lastIndexOf("\n", off - 1) + 1;
}

function indentOf(text, off) {
  return /^[ \t]*/.exec(text.slice(lineStart(text, off)))[0];
}

function endsWithBlankSep(text) {
  return text.length === 0 || /\n\n$/.test(text);
}

// New `\li{}` inside a `\ul` span; falls back to a fresh `\ul` at EOF.
function insertLi(text, cursorOff, outermost) {
  const enclosing = scanUls(text).filter(
    (s) => s.open < cursorOff && cursorOff <= s.close,
  );
  if (enclosing.length === 0) {
    const sep = text.length === 0 || text.endsWith("\n\n") ? "" : text.endsWith("\n") ? "\n" : "\n\n";
    const ins = `${sep}\\ul{\n  \\li{}\n}\n`;
    const base = text.length;
    return {
      start: base,
      end: base,
      text: ins,
      cursor: base + sep.length + "\\ul{\n  \\li{".length,
    };
  }
  enclosing.sort((a, b) => a.close - a.open - (b.close - b.open));
  const ul = outermost ? enclosing[enclosing.length - 1] : enclosing[0];
  const ulIndent = indentOf(text, ul.open);
  const body = text.slice(ul.open + 1, ul.close);
  const closeLineStart = lineStart(text, ul.close);
  const closeAlone =
    closeLineStart > ul.open && /^[ \t]*$/.test(text.slice(closeLineStart, ul.close));
  if (closeAlone) {
    // Match an existing direct child's indentation, else ulIndent + 2.
    const child = /\n([ \t]*)\\li\{/.exec(body);
    const indent = child ? child[1] : ulIndent + "  ";
    const ins = `${indent}\\li{}\n`;
    return {
      start: closeLineStart,
      end: closeLineStart,
      text: ins,
      cursor: closeLineStart + indent.length + "\\li{".length,
    };
  }
  // `\ul{...}` closed on the same line as content: put the new item on its
  // own line and move the brace down.
  const indent = ulIndent + "  ";
  const trimmedEnd = ul.open + 1 + body.replace(/\s+$/, "").length;
  const ins = `\n${indent}\\li{}\n${ulIndent}`;
  return {
    start: trimmedEnd,
    end: ul.close,
    text: ins,
    cursor: trimmedEnd + 1 + indent.length + "\\li{".length,
  };
}

function appendP(text) {
  const sep = text.length === 0 || text.endsWith("\n\n") ? "" : text.endsWith("\n") ? "\n" : "\n\n";
  const ins = `${sep}\\p{}\n`;
  return {
    start: text.length,
    end: text.length,
    text: ins,
    cursor: text.length + sep.length + "\\p{".length,
  };
}

// Insert `\tag{}` after the last line of the leading header block.
function insertTag(text) {
  const lines = text.split("\n");
  let offs = 0;
  let endOff = 0; // offset just past the last header line (incl. its \n)
  let i = 0;
  while (i < lines.length) {
    const line = lines[i];
    if (HEADER.test(line)) {
      // Swallow continuation lines of an unbalanced header command.
      let depth = 0;
      let j = i;
      let consumed = 0;
      for (; j < lines.length; j++) {
        const l = lines[j];
        if (j === i && /^\s*%/.test(l)) {
          consumed += l.length + 1;
          break;
        }
        for (let k = 0; k < l.length; k++) {
          if (l[k] === "\\") k++;
          else if (l[k] === "{") depth++;
          else if (l[k] === "}") depth--;
        }
        consumed += l.length + 1;
        if (depth <= 0) break;
      }
      offs += consumed;
      endOff = Math.min(offs, text.length);
      i = j + 1;
      continue;
    }
    if (/^\s*$/.test(line) || /^\s*%/.test(line)) {
      offs += line.length + 1;
      i++;
      continue;
    }
    break;
  }
  const atEof = endOff >= text.length;
  const noHeader = endOff === 0;
  let prefix = "";
  if (!noHeader && atEof && !text.endsWith("\n")) prefix = "\n";
  const suffix = noHeader && text.length > 0 ? "\n" : "";
  const ins = `${prefix}\\tag{}\n${suffix}`;
  return {
    start: endOff,
    end: endOff,
    text: ins,
    cursor: endOff + prefix.length + "\\tag{".length,
  };
}

module.exports = { scanUls, insertLi, appendP, insertTag };
