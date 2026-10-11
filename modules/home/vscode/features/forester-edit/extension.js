const vscode = require("vscode");
const edits = require("./edits");

async function apply(compute) {
  const editor = vscode.window.activeTextEditor;
  if (!editor) return;
  const doc = editor.document;
  const text = doc.getText();
  const r = compute(text, doc.offsetAt(editor.selection.active));
  const range = new vscode.Range(doc.positionAt(r.start), doc.positionAt(r.end));
  if (!(await editor.edit((b) => b.replace(range, r.text)))) return;
  const pos = editor.document.positionAt(r.cursor);
  editor.selection = new vscode.Selection(pos, pos);
  editor.revealRange(new vscode.Range(pos, pos));
}

function activate(context) {
  const reg = (id, fn) =>
    context.subscriptions.push(vscode.commands.registerCommand(id, () => apply(fn)));
  reg("forestEdit.insertLi", (t, c) => edits.insertLi(t, c, "inner"));
  reg("forestEdit.insertLiParent", (t, c) => edits.insertLi(t, c, "parent"));
  reg("forestEdit.insertLiOutermost", (t, c) => edits.insertLi(t, c, "outermost"));
  reg("forestEdit.appendP", (t) => edits.appendP(t));
  reg("forestEdit.insertTag", (t) => edits.insertTag(t));
}

module.exports = { activate };
