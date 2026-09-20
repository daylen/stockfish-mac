# Architecture

## PGN parsing and recovery

`SFMPGNFile` owns the ordered collection of games in a document. `SFMParser`
builds each game's move tree through `SFMPosition`, which validates moves
against the current position. A file opens when at least one game can be read.
Unreadable games remain in their original positions in the collection because
removing them would delete their text when the document autosaves.

Game boundaries and movetext tokenization share comment-boundary recognition.
Brace comments can span lines; semicolon comments and percent escape lines end
at the line boundary. Apparent headers inside comments remain comment text.
A valid header must match a complete tag pair before its fields are read.
Malformed headers remain in unread move text, and an unterminated comment or
variation reports a structural error rather than reaching substring operations.
An unclosed brace can consume later apparent headers: the reader preserves that
remainder instead of guessing where the comment was intended to end.

Tagless move fragments remain valid imports without a final result marker and
remain separate games when followed by a tagged game. Comment-only preambles
belong to the following game. Percent escape lines do not create games.

An illegal SAN move stops the affected line at its preceding legal move.
Readable main-line moves and sibling variations continue. The game records the
first rejected token in input order as `SFMChessGame.rejectedMove`. An illegal
first move in a variation leaves that variation empty without discarding the
rest of the game. A structurally empty or otherwise unreadable variation
rejects the game instead: an earlier rejection cannot make a later structural
error recoverable.

SAN tokens must match the supported move spelling in full before they reach
the board-aware SAN interpreter. Unrecognized tokens use the same rejected-move
recovery path without sending an empty string into the chess library.

Recovery requires `POSITION_ERROR_DOMAIN`, `ILLEGAL_MOVE_CODE`, and the
rejected SAN token in `REJECTED_MOVE_KEY`. Errors without a token do not identify
a safe truncation point. The optional parser output for that token does not
change parsing behavior.

## Saving and editing recovered games

`SFMDocument` autosaves in place. `SFMChessGame.hasUnreadMoveText` covers both a
partially recovered game and a structurally unreadable game. While it holds,
PGN serialization preserves the original move text, including line endings and
blank lines that determine comment boundaries. Tags are serialized separately.
Saving and reopening without edits does not accumulate separator lines.

A successful move edit makes the tree authoritative for subsequent saves and
clears the rejected token. The unread remainder is then omitted. This allows
the user to continue from the readable position without discarding their edit
on save. Preservation state participates in the same undo group as the move:
Undo restores the original text and rejection marker; Redo restores the edited
tree. Failed moves preserve both states. A game with no readable tree rejects
move edits.

Fully readable games use the tree serializer. Each node stores one comment body;
consecutive brace-comment bodies are joined with a space, and semicolon-comment
bodies begin a new line. Content and its order within the node survive saving,
reopening, and the transition from recovered text to an edited tree. Separate
original comment blocks and their placement relative to variations are not
represented. A comment containing a closing brace is exported as semicolon
lines, with line endings normalized to LF, so its content remains valid PGN.
This preserves comment content without claiming byte-for-byte serialization of
fully readable games.

## Document selection and analysis

`SFMWindowController` owns the selected game and synchronizes its position,
notation, and engine snapshot when selection changes. Selecting an unreadable
game reports the parse failure, then displays that game's starting position
and empty notation. Navigation and engine-move actions are disabled until a
game with a move tree is selected. The board's move path also reaches the
model's edit guard.

`SFMChessGame` copies used by the engine represent the selected position and
its move ancestry. They are analysis snapshots; document saving uses the
original games in `SFMPGNFile`.
