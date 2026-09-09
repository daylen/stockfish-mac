# Architecture

Architectural decisions for this project, newest first. Each entry records a
decision about the system's structure and the guarantees that hold at a
boundary, along with the alternatives weighed and the consequences accepted.

## 2026-09-09: A PGN file survives the games in it that cannot be read

`SFMParser` previously guaranteed all-or-nothing at its boundary: if any game
in a file failed to parse, `parseGamesFromString:` returned nil and the file
would not open. Real-world PGN does not earn that guarantee. The FIDE Olympiad
archives contain 51 games out of 3426 with genuinely illegal moves, and under
the old contract four such games made a 369-game file unopenable.

The boundary now distinguishes two kinds of failure:

- A move text naming an **illegal move** yields the moves before it. The game
  is returned, carrying the rejected SAN token in `SFMChessGame.rejectedMove`.
- A move text whose **structure** cannot be read, such as a variation
  containing no moves, is still rejected in full. The token stream itself is
  untrustworthy there, so no prefix of it can be trusted either.

A file is rejected only when nothing in it can be read.

The distinction is carried by the error code `SFMPosition` raises:
`ILLEGAL_MOVE_CODE`, which already meant exactly this and is what
`-doMove:error:` has always raised. `REJECTED_MOVE_KEY` in the `userInfo`
carries the offending token alongside it, so the code says the move was
illegal and the key says which one. A token is required before a game is
truncated, because `-doMove:error:` reports an illegal move without naming
one and truncating there would cut a game at a move its text never held.

**Consequence: a game whose move text was not fully read is written back out
verbatim.** `SFMDocument` autosaves in place. Re-serializing such a game from
its nodes would emit only the moves that parsed and silently discard the rest,
turning a file this change made openable into one missing data. `-[SFMChessGame
pgnString]` therefore returns the original move text while
`hasUnreadMoveText` holds.

That flag covers both a partially read game and one that could not be read at
all, and the latter stays in `SFMPGNFile.games` rather than being filtered out:
a game dropped from the list is a game deleted from the file the next time any
of its neighbours is saved. Such a game cannot be displayed, so selecting it
reports that its moves could not be read and leaves the window open.

The flag is cleared by the first edit. From that point the move tree, not the
text on disk, is what the game means, and continuing to write the original text
would discard the user's own moves.

**Alternatives weighed.** Dropping unreadable games entirely was simpler and
kept every listed game trustworthy, but removed games with no trace. Keeping
them truncated but unmarked risked a truncated game reading as a complete one.
Marking them costs a property on `SFMChessGame` and a string in the game list.
