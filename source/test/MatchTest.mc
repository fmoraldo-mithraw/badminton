using Toybox.System as Sys;

module MatchTest {

	(:test)
	function testNewMatch(logger) {
		var match = new Match(SINGLE, 1, YOU, 21, 30);
		BetterTest.assertEqual(match.getType(), SINGLE, "Match is created with correct type");
		BetterTest.assertEqual(match.getSetsNumber(), 1, "Match is created with corret number of set");
		BetterTest.assertEqual(match.getCurrentSetIndex(), 0, "Match current set index returns the correct index");
		BetterTest.assertEqual(match.getCurrentSet().getBeginner(), YOU, "Match is created with correct player");

		BetterTest.assertEqual(match.getTotalRalliesNumber(), 0, "Newly created match has 0 rally");
		BetterTest.assertFalse(match.hasEnded(), "Newly created match has not ended");
		BetterTest.assertNull(match.getWinner(), "Newly created match has no winner");
		BetterTest.assertEqual(match.getTotalScore(YOU), 0, "Newly created match has a total score of 0 for player 1");
		BetterTest.assertEqual(match.getTotalScore(OPPONENT), 0, "Newly created match has a total score of 0 for player 2");

		BetterTest.assertEqual(match.getCurrentSet().getScore(YOU), 0, "Newly created match has a set score of 0 for player 1");
		BetterTest.assertEqual(match.getCurrentSet().getScore(OPPONENT), 0, "Newly created match has a set score of 0 for player 2");

		BetterTest.assertEqual(match.getDuration().value(), 0, "Newly created match has a duration of 0");
		return true;
	}

	(:test)
	function testBeginMatch(logger) {
		var match = new Match(SINGLE, 1, YOU, 21, 30);
		//BetterTest.assertEqual(match.beginner, YOU, "Beginner of match began with player 1 is player 1");

		BetterTest.assertFalse(match.hasEnded(), "Began match has not ended");

		BetterTest.assertEqual(match.getTotalRalliesNumber(), 0, "Just began match has 0 rally");
		BetterTest.assertNull(match.getWinner(), "Just began match has now winner");
		BetterTest.assertNotNull(match.getDuration(), "Began match has a non null duration");
		return true;
	}

	(:test)
	function testScore(logger) {
		var match = new Match(SINGLE, 1, YOU, 21, 30);
		var set = match.getCurrentSet();

		match.score(YOU);

		BetterTest.assertEqual(match.getTotalScore(YOU), 1, "Score of player 1 is set to 1 after player 1 scored once");
		BetterTest.assertEqual(match.getTotalScore(OPPONENT), 0, "Score of player 2 is still 0 after player 1 scored once");

		BetterTest.assertEqual(set.getScore(YOU), 1, "Score of player 1 is set to 1 after player 1 scored");
		BetterTest.assertEqual(set.getScore(OPPONENT), 0, "Score of player 2 is still 0 after player 1 scored");

		match.score(YOU);
		BetterTest.assertEqual(set.getScore(YOU), 2, "Score of player 1 is set to 2 after player 1 scored twice");
		BetterTest.assertEqual(set.getScore(OPPONENT), 0, "Score of player 2 is still 0 after player 1 scored twice");

		BetterTest.assertFalse(match.hasEnded(), "Began match has not ended");
		BetterTest.assertEqual(match.getTotalRalliesNumber(), 2, "Match with 2 rallies has 2 rally number");
		BetterTest.assertNull(match.getWinner(), "Just began match has no winner");
		BetterTest.assertNotNull(match.getDuration(), "Began match has a non null duration");

		match.score(YOU);
		match.score(OPPONENT);
		BetterTest.assertEqual(set.getScore(YOU), 3, "Score of player 1 who scored twice is 2");
		BetterTest.assertEqual(set.getScore(OPPONENT), 1, "Score of player 2 who scored once is 1");
		return true;
	}

	(:test)
	function testUndo(logger) {
		var match = new Match(SINGLE, 1, YOU, 21, 30);
		var set = match.getCurrentSet();

		match.undo();
		BetterTest.assertEqual(match.getTotalScore(YOU), 0, "Undo when match has not begun does nothing");
		BetterTest.assertEqual(match.getTotalScore(OPPONENT), 0, "Undo when match has not begun does nothing");
		BetterTest.assertEqual(set.getScore(YOU), 0, "Undo when match has not begun does nothing");
		BetterTest.assertEqual(set.getScore(OPPONENT), 0, "Undo when match has not begun does nothing");

		match.score(YOU);
		match.undo();

		BetterTest.assertEqual(match.getTotalScore(YOU), 0, "Undo removes a point from the last player who scored");
		BetterTest.assertEqual(match.getTotalScore(OPPONENT), 0, "Undo does not touch the score of the other player");
		BetterTest.assertEqual(set.getScore(YOU), 0, "Undo removes a point from the last player who scored");
		BetterTest.assertEqual(set.getScore(OPPONENT), 0, "Undo does not touch the score of the other player");

		match.undo();
		BetterTest.assertEqual(match.getTotalScore(YOU), 0, "Undo when match has not begun does nothing");
		BetterTest.assertEqual(match.getTotalScore(OPPONENT), 0, "Undo when match has not begun does nothing");

		match.score(YOU);
		match.score(YOU);
		match.score(OPPONENT);
		match.score(YOU);
		BetterTest.assertEqual(match.getTotalScore(YOU), 3, "Score of player 1 is now 3");
		BetterTest.assertEqual(match.getTotalScore(OPPONENT), 1, "Score of player 2 is now 1");

		match.undo();
		BetterTest.assertEqual(match.getTotalScore(YOU), 2, "Undo removes a point from the last player who scored");
		BetterTest.assertEqual(match.getTotalScore(OPPONENT), 1, "Undo does not touch the score of the other player");

		match.undo();
		BetterTest.assertEqual(match.getTotalScore(OPPONENT), 0, "Undo does not touch the score of the other player");
		BetterTest.assertEqual(match.getTotalScore(YOU), 2, "Undo removes a point from the last player who scored");
		return true;
	}

	(:test)
	function testEnd(logger) {
		var match = new Match(SINGLE, 1, YOU, 3, 5);
		var set = match.getCurrentSet();

		match.score(YOU);
		match.score(YOU);
		match.score(YOU);
		BetterTest.assertEqual(set.getScore(YOU), 3, "Score of player 1 is now 3");
		BetterTest.assertTrue(match.hasEnded(), "Match has ended if maximum point has been reached");

		match.undo();
		BetterTest.assertEqual(set.getScore(YOU), 2, "Score of player 1 is now 2");
		BetterTest.assertFalse(match.hasEnded(), "Match has not ended if no player has reached the maximum point");

		match.score(OPPONENT);
		match.score(OPPONENT);
		match.score(YOU);
		BetterTest.assertEqual(set.getScore(YOU), 3, "Score of player 1 is now 3");
		BetterTest.assertEqual(set.getScore(OPPONENT), 2, "Score of player 2 is now 2");
		BetterTest.assertFalse(match.hasEnded(), "Match has not ended if there is not a difference of two points");

		match.score(YOU);
		match.score(YOU);
		BetterTest.assertEqual(set.getScore(YOU), 4, "Score of player 1 is now 4");
		BetterTest.assertTrue(match.hasEnded(), "Match has ended if absolute maximum point has been reached");

		match.score(YOU);
		BetterTest.assertEqual(set.getScore(YOU), 4, "Score after match has ended does nothing");
		match.score(OPPONENT);
		BetterTest.assertEqual(set.getScore(OPPONENT), 2, "Score after match has ended does nothing");
		return true;
	}
}
