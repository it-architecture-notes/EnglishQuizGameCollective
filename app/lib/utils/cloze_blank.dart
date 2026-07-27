/// Shared cloze blank token helpers (ClozeSequence parser + UI).
///
/// Blank markers are 2+ underscores. Surrounding punctuation such as
/// `.` `!` `?` `,` `;` `:` and quotes/brackets is stripped for detection
/// and preserved when rendering filled answers.

/// Strips light wrapping punctuation so `_____!` / `_____?` / `_____.` count as blanks.
String stripClozeBlankAffixes(String raw) {
  var t = raw.trim();
  const leading = ' "\'([{«';
  const trailing = '.,!?;:\'" )]}»\u2026';
  while (t.isNotEmpty && leading.contains(t[0])) {
    t = t.substring(1);
  }
  while (t.isNotEmpty && trailing.contains(t[t.length - 1])) {
    t = t.substring(0, t.length - 1);
  }
  return t;
}

/// True when a space-delimited token is a blank marker (2+ underscores, optional affixes).
bool isClozeBlankToken(String s) =>
    RegExp(r'^_{2,}$').hasMatch(stripClozeBlankAffixes(s));
