module MatchTest {

	function create_match_config(type, sets, beginner, server, maximum_points, absolute_maximum_points) {
		var config = new MatchConfig();
		config.type = type;
		config.sets = sets;
		config.beginner = beginner;
		config.server = server;
		config.maximumPoints = maximum_points;
		config.absoluteMaximumPoints = absolute_maximum_points;
		return config;
	}

	(:test)
	function testNewMatch(logger) {
		var match = new Match(create_match_config(SINGLE, 1, YOU, true, 21, 30));
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
		var match = new Match(create_match_config(SINGLE, 1, YOU, true, 21, 30));
		//BetterTest.assertEqual(match.beginner, YOU, "Beginner of match began with player 1 is player 1");

		BetterTest.assertFalse(match.hasEnded(), "Began match has not ended");

		BetterTest.assertEqual(match.getTotalRalliesNumber(), 0, "Just began match has 0 rally");
		BetterTest.assertNull(match.getWinner(), "Just began match has now winner");
		BetterTest.assertNotNull(match.getDuration(), "Began match has a non null duration");
		return true;
	}

	(:test)
	function testScore(logger) {
		var match = new Match(create_match_config(SINGLE, 1, YOU, true, 21, 30));
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
		var match = new Match(create_match_config(SINGLE, 1, YOU, true, 21, 30));
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
		var match = new Match(create_match_config(SINGLE, 1, YOU, true, 3, 5));
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

	(:test)
	function testServer(logger) {
		//single, player begins the match
		var match = new Match(create_match_config(SINGLE, 1, YOU, true, 21, 30));
		BetterTest.assertTrue(match.getPlayerTeamIsServer(), "In singles, player team serves if it begins a match");
		BetterTest.assertTrue(match.getPlayerIsServer(), "In singles, the player is the server if he begins the match");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_RIGHT, "In singles, the player serves from the right if his score is even");

		match.score(YOU); //1-0
		BetterTest.assertTrue(match.getPlayerTeamIsServer(), "In singles, player team serves while it's winning rallies");
		BetterTest.assertTrue(match.getPlayerIsServer(), "In singles, the player is the server while he's winning rallies");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_LEFT, "In singles, the player serves from the left if his score is odd");

		match.score(YOU); //2-0
		BetterTest.assertTrue(match.getPlayerTeamIsServer(), "In singles, player team serves while it's winning rallies");
		BetterTest.assertTrue(match.getPlayerIsServer(), "In singles, the player is the server while he's winning rallies");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_RIGHT, "In singles, the player serves from the right if his score is even");

		match.score(OPPONENT); //2-1
		BetterTest.assertFalse(match.getPlayerTeamIsServer(), "In singles, player team does not serve if it lost a rally");
		BetterTest.assertFalse(match.getPlayerIsServer(), "In singles, the player is not the server if he lost a rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_LEFT, "In singles, the player receives the service on the left if the opponent serves and his score is odd");

		match.score(YOU); //3-1
		BetterTest.assertTrue(match.getPlayerTeamIsServer(), "In singles, player team serves if it won a rally back");
		BetterTest.assertTrue(match.getPlayerIsServer(), "In singles, the player is the server if he won a rally back");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_LEFT, "In singles, the player serves from the left if his score is odd");

		match.discard();

		//single, opponent begins the match
		match = new Match(create_match_config(SINGLE, 1, OPPONENT, true, 21, 30));
		BetterTest.assertFalse(match.getPlayerTeamIsServer(), "In singles, player team does not serve if the opponent begins a match");
		BetterTest.assertFalse(match.getPlayerIsServer(), "In singles, the player is not the server if the opponent begins the match");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_RIGHT, "In singles, the player receives the service on the right if the opponent serves and his score is even");

		match.score(YOU); //1-0
		BetterTest.assertTrue(match.getPlayerTeamIsServer(), "In singles, player team serves if it won a rally");
		BetterTest.assertTrue(match.getPlayerIsServer(), "In singles, the player is the server if he won a rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_LEFT, "In singles, the player serves from the left if his score is odd");

		match.score(YOU); //2-0
		BetterTest.assertTrue(match.getPlayerTeamIsServer(), "In singles, player team serves while it's winning rallies");
		BetterTest.assertTrue(match.getPlayerIsServer(), "In singles, the player is the server while he's winning rallies");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_RIGHT, "In singles, the player serves from the right if his score is even");

		match.score(OPPONENT); //2-1
		BetterTest.assertFalse(match.getPlayerTeamIsServer(), "In singles, player team does not serve if it lost a rally");
		BetterTest.assertFalse(match.getPlayerIsServer(), "In singles, the player is not the server if he lost a rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_LEFT, "In singles, the player receives the service on the left if the opponent serves and his score is even");

		match.score(YOU); //3-1
		BetterTest.assertTrue(match.getPlayerTeamIsServer(), "In singles, player team serves if it won a rally back");
		BetterTest.assertTrue(match.getPlayerIsServer(), "In singles, the player is the server if he won a rally back");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_LEFT, "In singles, the player serves from the left if his score is odd");

		match.discard();

		//double, player team begins the match and is the first server
		match = new Match(create_match_config(DOUBLE, 1, YOU, true, 21, 30));
		BetterTest.assertTrue(match.getPlayerTeamIsServer(), "In doubles, player team serves if it begins a match");
		BetterTest.assertTrue(match.getPlayerIsServer(), "In doubles, the player is the server if his team begins the match and he is the first server");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_RIGHT, "In doubles, the player serves from the right if his team's score is even");

		match.score(OPPONENT); //0-1
		BetterTest.assertFalse(match.getPlayerTeamIsServer(), "In doubles, player team serves if it won a rally");
		BetterTest.assertFalse(match.getPlayerIsServer(), "In doubles, the player is the server if he won a rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_RIGHT, "In doubles, the player stays in place after his team lost the service");

		match.score(YOU); //1-1
		BetterTest.assertTrue(match.getPlayerTeamIsServer(), "In doubles, player team serves if it won a rally");
		BetterTest.assertFalse(match.getPlayerIsServer(), "In doubles, the player teammate is the server if he won a rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_RIGHT, "In doubles, the player takes the non serving corner if his teammate is serving and his team's score is odd");

		match.undo(); //0-1
		BetterTest.assertFalse(match.getPlayerTeamIsServer(), "In doubles, player team serves if it won a rally");
		BetterTest.assertFalse(match.getPlayerIsServer(), "In doubles, the player is the server if he won a rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_RIGHT, "In doubles, the player stays in place after his team lost the service");

		match.undo(); //0-0
		BetterTest.assertTrue(match.getPlayerTeamIsServer(), "In doubles, player team serves if it begins a match");
		BetterTest.assertTrue(match.getPlayerIsServer(), "In doubles, the player is the server if his team begins the match and he is the first server");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_RIGHT, "In doubles, the player serves from the right if his team's score is even");

		match.score(YOU); //1-0
		BetterTest.assertTrue(match.getPlayerTeamIsServer(), "In doubles, player team serves if it won a rally");
		BetterTest.assertTrue(match.getPlayerIsServer(), "In doubles, the player is the server if he won a rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_LEFT, "In doubles, the player serves from the left if his team's score is odd");

		match.score(YOU); //2-0
		BetterTest.assertTrue(match.getPlayerTeamIsServer(), "In doubles, player team serves if it won another rally");
		BetterTest.assertTrue(match.getPlayerIsServer(), "In doubles, the player is the server if he won another rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_RIGHT, "In doubles, the player serves from the right if his team's score is even");

		match.score(OPPONENT); //2-1
		BetterTest.assertFalse(match.getPlayerTeamIsServer(), "In doubles, player team does not serve if it lost a rally");
		BetterTest.assertFalse(match.getPlayerIsServer(), "In doubles, the player is not the server if he lost a rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_RIGHT, "In doubles, the player stays in place after his team lost the service");

		match.score(YOU); //3-1
		BetterTest.assertTrue(match.getPlayerTeamIsServer(), "In doubles, player team serves if it won a rally");
		BetterTest.assertFalse(match.getPlayerIsServer(), "In doubles, the player teammate is the server if he won a rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_RIGHT, "In doubles, the player takes the non serving corner if his teammate is serving and his team's score is odd");

		match.score(OPPONENT); //3-2
		BetterTest.assertFalse(match.getPlayerTeamIsServer(), "In doubles, player team does not serve if it lost a rally");
		BetterTest.assertFalse(match.getPlayerIsServer(), "In doubles, the player is not the server if he lost a rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_RIGHT, "In doubles, the player stays in place after his team lost the service");

		match.score(YOU); //4-2
		BetterTest.assertTrue(match.getPlayerTeamIsServer(), "In doubles, player team serves if it won a rally");
		BetterTest.assertTrue(match.getPlayerIsServer(), "In doubles, the player is the server if he won a rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_RIGHT, "In doubles, the player serves from the right if his team's score is even");

		match.discard();

		//double, player team begins the match and his teammate is the first server
		match = new Match(create_match_config(DOUBLE, 1, YOU, false, 21, 30));
		BetterTest.assertTrue(match.getPlayerTeamIsServer(), "In doubles, player team serves if it begins a match");
		BetterTest.assertFalse(match.getPlayerIsServer(), "In doubles, player is not the server if his team begins the match and his teammate is the first server");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_LEFT, "In doubles, the player takes the non serving corner if his teammate is serving and his team's score is even");

		match.score(OPPONENT); //0-1
		BetterTest.assertFalse(match.getPlayerTeamIsServer(), "In doubles, player team serves if it won a rally");
		BetterTest.assertFalse(match.getPlayerIsServer(), "In doubles, the player is the server if he won a rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_LEFT, "In doubles, the player stays in place after his team lost the service");

		match.score(YOU); //1-1
		BetterTest.assertTrue(match.getPlayerTeamIsServer(), "In doubles, player team serves if it won a rally");
		BetterTest.assertTrue(match.getPlayerIsServer(), "In doubles, the player teammate is the server if he won a rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_LEFT, "In doubles, the player serves from the left if his team's score is odd");

		match.undo(); //0-1
		BetterTest.assertFalse(match.getPlayerTeamIsServer(), "In doubles, player team serves if it won a rally");
		BetterTest.assertFalse(match.getPlayerIsServer(), "In doubles, the player is the server if he won a rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_LEFT, "In doubles, the player stays in place after his team lost the service");

		match.undo(); //0-0
		BetterTest.assertTrue(match.getPlayerTeamIsServer(), "In doubles, player team serves if it begins a match");
		BetterTest.assertFalse(match.getPlayerIsServer(), "In doubles, the player is not the server if his team begins the match and his teammate is the first server");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_LEFT, "In doubles, the player takes the non serving corner if his teammate is serving and his team's score is even");

		match.score(YOU); //1-0
		BetterTest.assertTrue(match.getPlayerTeamIsServer(), "In doubles, player team serves if it won a rally");
		BetterTest.assertFalse(match.getPlayerIsServer(), "In doubles, the player teammate is the server if he won a rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_RIGHT, "In doubles, the player takes the non serving corner if his teammate is serving and his team's score is odd");

		match.score(YOU); //2-0
		BetterTest.assertTrue(match.getPlayerTeamIsServer(), "In doubles, player team serves if it won another rally");
		BetterTest.assertFalse(match.getPlayerIsServer(), "In doubles, the player teammate is the server if he won another rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_LEFT, "In doubles, the player takes the non serving corner if his teammate is serving and his team's score is even");

		match.score(OPPONENT); //2-1
		BetterTest.assertFalse(match.getPlayerTeamIsServer(), "In doubles, player team does not serve if it lost a rally");
		BetterTest.assertFalse(match.getPlayerIsServer(), "In doubles, the player is not the server if he lost a rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_LEFT, "In doubles, the player stays in place after his team lost the service");

		match.score(YOU); //3-1
		BetterTest.assertTrue(match.getPlayerTeamIsServer(), "In doubles, player team serves if it won a rally");
		BetterTest.assertTrue(match.getPlayerIsServer(), "In doubles, the player is the server if he won a rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_LEFT, "In doubles, the player serves from the left if his team's score is odd");

		match.score(OPPONENT); //3-2
		BetterTest.assertFalse(match.getPlayerTeamIsServer(), "In doubles, player team does not serve if it lost a rally");
		BetterTest.assertFalse(match.getPlayerIsServer(), "In doubles, the player is not the server if he lost a rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_LEFT, "In doubles, the player stays in place after his team lost the service");

		match.score(YOU); //4-2
		BetterTest.assertTrue(match.getPlayerTeamIsServer(), "In doubles, player team serves if it won a rally");
		BetterTest.assertFalse(match.getPlayerIsServer(), "In doubles, the player teammate is the server if he won a rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_LEFT, "In doubles, the player takes the non serving corner if his teammate is serving and his team's score is even");

		match.discard();

		//double, opponent team begins the match and the player is the first server
		match = new Match(create_match_config(DOUBLE, 1, OPPONENT, true, 21, 30));
		BetterTest.assertFalse(match.getPlayerTeamIsServer(), "In doubles, player team does not serve if the opponent team begins a match");
		BetterTest.assertFalse(match.getPlayerIsServer(), "In doubles, the player is not the server if the opponent team begins the match");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_LEFT, "In doubles, the player is ready to be serving when he will regain the service if the opponent team serves first");

		match.score(YOU); //1-0
		BetterTest.assertTrue(match.getPlayerTeamIsServer(), "In doubles, player team serves if it won a rally");
		BetterTest.assertTrue(match.getPlayerIsServer(), "In doubles, the player is the server if he won a rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_LEFT, "In doubles, the player serves from the left if his team's score is odd");

		match.score(YOU); //2-0
		BetterTest.assertTrue(match.getPlayerTeamIsServer(), "In doubles, player team serves if it won another rally");
		BetterTest.assertTrue(match.getPlayerIsServer(), "In doubles, the player is the server if he won another rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_RIGHT, "In doubles, the player serves from the right if his team's score is even");

		match.undo(); //1-0
		BetterTest.assertTrue(match.getPlayerTeamIsServer(), "In doubles, player team serves if it won a rally");
		BetterTest.assertTrue(match.getPlayerIsServer(), "In doubles, the player is the server if he won a rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_LEFT, "In doubles, the player serves from the left if his team's score is odd");

		match.undo(); //0-0
		BetterTest.assertFalse(match.getPlayerTeamIsServer(), "In doubles, player team does not serve if the opponent team begins a match");
		BetterTest.assertFalse(match.getPlayerIsServer(), "In doubles, the player is not the server if the opponent team begins the match");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_LEFT, "In doubles, the player is ready to be serving when he will regain the service if the opponent team serves first");

		match.score(OPPONENT); //0-1
		BetterTest.assertFalse(match.getPlayerTeamIsServer(), "In doubles, player team does not serve if it lost a rally");
		BetterTest.assertFalse(match.getPlayerIsServer(), "In doubles, the player is not the server if he lost a rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_LEFT, "In doubles, the player is ready to be serving when he will regain the service if the opponent team serves first");

		match.score(OPPONENT); //0-2
		BetterTest.assertFalse(match.getPlayerTeamIsServer(), "In doubles, player team does not serve if it lost another rally");
		BetterTest.assertFalse(match.getPlayerIsServer(), "In doubles, the player is not the server if he lost another rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_LEFT, "In doubles, the player is ready to be serving when he will regain the service if the opponent team serves first");

		match.score(YOU); //1-0
		BetterTest.assertTrue(match.getPlayerTeamIsServer(), "In doubles, player team serves if it won a rally");
		BetterTest.assertTrue(match.getPlayerIsServer(), "In doubles, the player is the server if he won a rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_LEFT, "In doubles, the player serves from the left if his team's score is odd");

		match.score(YOU); //2-0
		BetterTest.assertTrue(match.getPlayerTeamIsServer(), "In doubles, player team serves if it won another rally");
		BetterTest.assertTrue(match.getPlayerIsServer(), "In doubles, the player is the server if he won another rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_RIGHT, "In doubles, the player serves from the right if his team's score is even");

		match.score(OPPONENT); //2-1
		BetterTest.assertFalse(match.getPlayerTeamIsServer(), "In doubles, player team does not serve if it lost a rally");
		BetterTest.assertFalse(match.getPlayerIsServer(), "In doubles, the player is not the server if he lost a rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_RIGHT, "In doubles, the player stays in place after his team lost the service");

		match.score(YOU); //3-1
		BetterTest.assertTrue(match.getPlayerTeamIsServer(), "In doubles, player team serves if it won a rally");
		BetterTest.assertFalse(match.getPlayerIsServer(), "In doubles, the player teammate is the server if he won a rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_RIGHT, "In doubles, the player takes the non serving corner if his teammate is serving and his team's score is even");

		match.discard();

		//double, opponent team begins the match and his teammate is the first server
		match = new Match(create_match_config(DOUBLE, 1, OPPONENT, false, 21, 30));
		BetterTest.assertFalse(match.getPlayerTeamIsServer(), "In doubles, player team does not serve if the opponent team begins a match");
		BetterTest.assertFalse(match.getPlayerIsServer(), "In doubles, the player is not the server if the opponent team begins the match");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_RIGHT, "In doubles, the player is ready to be non serving when his team will regain the service if the opponent team serves first");

		match.score(YOU); //1-0
		BetterTest.assertTrue(match.getPlayerTeamIsServer(), "In doubles, player team serves if it won a rally");
		BetterTest.assertFalse(match.getPlayerIsServer(), "In doubles, the player teammate is the server if he won a rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_RIGHT, "In doubles, the player takes the non serving corner if his teammate is serving and his team's score is odd");

		match.score(YOU); //2-0
		BetterTest.assertTrue(match.getPlayerTeamIsServer(), "In doubles, player team serves if it won another rally");
		BetterTest.assertFalse(match.getPlayerIsServer(), "In doubles, the player teammate is the server if he won another rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_LEFT, "In doubles, the player takes the non serving corner if his teammate is serving and his team's score is even");

		match.undo(); //1-0
		BetterTest.assertTrue(match.getPlayerTeamIsServer(), "In doubles, player team serves if it won a rally");
		BetterTest.assertFalse(match.getPlayerIsServer(), "In doubles, the player teammate is the server if he won a rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_RIGHT, "In doubles, the player takes the non serving corner if his teammate is serving and his team's score is odd");

		match.undo(); //0-0
		BetterTest.assertFalse(match.getPlayerTeamIsServer(), "In doubles, player team does not serve if the opponent team begins a match");
		BetterTest.assertFalse(match.getPlayerIsServer(), "In doubles, the player is not the server if the opponent team begins the match");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_RIGHT, "In doubles, the player is ready to be non serving when his team will regain the service if the opponent team serves first");

		match.score(OPPONENT); //0-1
		BetterTest.assertFalse(match.getPlayerTeamIsServer(), "In doubles, player team does not serve if it lost a rally");
		BetterTest.assertFalse(match.getPlayerIsServer(), "In doubles, the player is not the server if he lost a rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_RIGHT, "In doubles, the player is ready to be non serving when his team will regain the service if the opponent team serves first");

		match.score(OPPONENT); //0-2
		BetterTest.assertFalse(match.getPlayerTeamIsServer(), "In doubles, player team does not serve if it lost another rally");
		BetterTest.assertFalse(match.getPlayerIsServer(), "In doubles, the player is not the server if he lost another rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_RIGHT, "In doubles, the player is ready to be non serving when his team will regain the service if the opponent team serves first");

		match.score(YOU); //1-2
		BetterTest.assertTrue(match.getPlayerTeamIsServer(), "In doubles, player team serves if it won a rally");
		BetterTest.assertFalse(match.getPlayerIsServer(), "In doubles, the player teammate is the server if he won a rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_RIGHT, "In doubles, the player takes the non serving corner if his teammate is serving and his team's score is odd");

		match.score(YOU); //2-2
		BetterTest.assertTrue(match.getPlayerTeamIsServer(), "In doubles, player team serves if it won another rally");
		BetterTest.assertFalse(match.getPlayerIsServer(), "In doubles, the player is the server if he won another rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_LEFT, "In doubles, the player takes the non serving corner if his teammate is serving and his team's score is even");

		match.score(OPPONENT); //2-3
		BetterTest.assertFalse(match.getPlayerTeamIsServer(), "In doubles, player team does not serve if it lost a rally");
		BetterTest.assertFalse(match.getPlayerIsServer(), "In doubles, the player is not the server if he lost a rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_LEFT, "In doubles, the player stays in place after his team lost the service");

		match.score(YOU); //3-3
		BetterTest.assertTrue(match.getPlayerTeamIsServer(), "In doubles, player team serves if it won a rally");
		BetterTest.assertTrue(match.getPlayerIsServer(), "In doubles, the player is the server if he won a rally");
		BetterTest.assertEqual(match.getPlayerCorner(), YOU_LEFT, "In doubles, the player serves from the left if his team's score is odd");

		return true;
	}
}
