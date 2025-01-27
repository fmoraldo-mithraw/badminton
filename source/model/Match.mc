using Toybox.Time;
using Toybox.ActivityRecording;
using Toybox.Activity;
using Toybox.FitContributor;
using Toybox.WatchUi;

enum Player {
	YOU = 1,
	OPPONENT = 2
}

enum MatchType {
	SINGLE = 1,
	DOUBLE = 2
}

enum Corner {
	OPPONENT_RIGHT = 0, //top left corner on the screen
	OPPONENT_LEFT = 1, //top right corner on the screen
	YOU_LEFT = 2, //bottom left corner on the screen
	YOU_RIGHT = 3 //bottom right corner on the screen
}

class MatchConfig {
	public var step = 0;
	public var type;
	public var sets;
	public var beginner;
	public var server;
	public var maximumPoints;
	public var absoluteMaximumPoints;

	function isValid() {
		return type == SINGLE && step == 3 || step == 4;
	}
}

class Match {
	static const MAX_SETS = 11;

	const OPPOSITE_CORNER = {
		OPPONENT_RIGHT => YOU_RIGHT,
		OPPONENT_LEFT => YOU_LEFT,
		YOU_LEFT => OPPONENT_LEFT,
		YOU_RIGHT => OPPONENT_RIGHT
	};

	const TOTAL_SCORE_PLAYER_1_FIELD_ID = 0;
	const TOTAL_SCORE_PLAYER_2_FIELD_ID = 1;
	const SET_WON_PLAYER_1_FIELD_ID = 2;
	const SET_WON_PLAYER_2_FIELD_ID = 3;
	const SET_SCORE_PLAYER_1_FIELD_ID = 4;
	const SET_SCORE_PLAYER_2_FIELD_ID = 5;
	const SET_SCORE = 6;

	private var type; //type of the match, SINGLE or DOUBLE
	private var sets; //array of all sets, containing null for a set not played

	private var server; //in double, true if the player 1 (watch carrier) is currently the server
	private var winner; //store the winner of the match, YOU or OPPONENT

	private var maximumPoints;
	private var absoluteMaximumPoints;

	private var session;
	private var fieldSetPlayer1;
	private var fieldSetPlayer2;
	private var fieldSetScorePlayer1;
	private var fieldSetScorePlayer2;
	private var fieldScorePlayer1;
	private var fieldScorePlayer2;

	function initialize(config) {
		type = config.type;

		//in singles, the server is necessary the watch carrier
		//in doubles, server is either the watch carrier or his teammate
		server = config.type == DOUBLE ? config.server : true;

		//prepare array of sets and create first set
		sets = new [config.sets];
		sets[0] = new MatchSet(config.beginner);
		for(var i = 1; i < config.sets; i++) {
			sets[i] = null;
		}

		maximumPoints = config.maximumPoints;
		absoluteMaximumPoints = config.absoluteMaximumPoints;

		//manage activity session
		session = ActivityRecording.createSession({:sport => ActivityRecording.SPORT_GENERIC, :subSport => ActivityRecording.SUB_SPORT_MATCH, :name => WatchUi.loadResource(Rez.Strings.fit_activity_name)});
		fieldSetPlayer1 = session.createField("set_player_1", SET_WON_PLAYER_1_FIELD_ID, FitContributor.DATA_TYPE_SINT8, {:mesgType => FitContributor.MESG_TYPE_SESSION, :units => WatchUi.loadResource(Rez.Strings.fit_set_unit_label)});
		fieldSetPlayer2 = session.createField("set_player_2", SET_WON_PLAYER_2_FIELD_ID, FitContributor.DATA_TYPE_SINT8, {:mesgType => FitContributor.MESG_TYPE_SESSION, :units => WatchUi.loadResource(Rez.Strings.fit_set_unit_label)});
		fieldScorePlayer1 = session.createField("score_player_1", TOTAL_SCORE_PLAYER_1_FIELD_ID, FitContributor.DATA_TYPE_SINT8, {:mesgType => FitContributor.MESG_TYPE_SESSION, :units => WatchUi.loadResource(Rez.Strings.fit_score_unit_label)});
		fieldScorePlayer2 = session.createField("score_player_2", TOTAL_SCORE_PLAYER_2_FIELD_ID, FitContributor.DATA_TYPE_SINT8, {:mesgType => FitContributor.MESG_TYPE_SESSION, :units => WatchUi.loadResource(Rez.Strings.fit_score_unit_label)});
		fieldSetScorePlayer1 = session.createField("set_score_player_1", SET_SCORE_PLAYER_1_FIELD_ID, FitContributor.DATA_TYPE_SINT8, {:mesgType => FitContributor.MESG_TYPE_LAP, :units => WatchUi.loadResource(Rez.Strings.fit_score_unit_label)});
		fieldSetScorePlayer2 = session.createField("set_score_player_2", SET_SCORE_PLAYER_2_FIELD_ID, FitContributor.DATA_TYPE_SINT8, {:mesgType => FitContributor.MESG_TYPE_LAP, :units => WatchUi.loadResource(Rez.Strings.fit_score_unit_label)});
		session.start();

		Application.getApp().getBus().dispatch(new BusEvent(:onMatchBegin, null));
	}

	function save() {
		//session can only be save once
		fieldSetPlayer1.setData(getSetsWon(YOU));
		fieldSetPlayer2.setData(getSetsWon(OPPONENT));
		session.stop();
		session.save();
	}

	function discard() {
		session.discard();
	}

	hidden function end(winner_player) {
		winner = winner_player;

		Application.getApp().getBus().dispatch(new BusEvent(:onMatchEnd, winner));
	}

	function nextSet() {
		//manage activity session
		session.addLap();
		fieldSetScorePlayer1.setData(0);
		fieldSetScorePlayer2.setData(0);

		//the player who won the previous game will serve first in the next set
		var i = getCurrentSetIndex();
		var beginner = sets[i].getWinner();

		//create next set
		sets[i +1] = new MatchSet(beginner);
	}

	function getSetsNumber() {
		return sets.size();
	}

	function getCurrentSetIndex() {
		var i = 0;
		while(i < sets.size() && sets[i] != null) {
			i++;
		}
		return i - 1;
	}

	function getCurrentSet() {
		return sets[getCurrentSetIndex()];
	}

	function score(scorer) {
		if(!hasEnded()) {
			var set = getCurrentSet();
			set.score(scorer);
			// update lap score 
			fieldSetScorePlayer1.setData(set.getScore(YOU));
			fieldSetScorePlayer2.setData(set.getScore(OPPONENT));
			//detect if match has a set winner
			var set_winner = isSetWon(set);
			if(set_winner != null) {
				set.end(set_winner);
				var match_winner = isWon();
				if(match_winner != null) {
					end(match_winner);
				}
			}
		}
	}

	hidden function isSetWon(set) {
		var scorePlayer1 = set.getScore(YOU);
		var scorePlayer2 = set.getScore(OPPONENT);
		if(scorePlayer1 >= absoluteMaximumPoints || scorePlayer1 >= maximumPoints && (scorePlayer1 - scorePlayer2) > 1) {
			return YOU;
		}
		if(scorePlayer2 >= absoluteMaximumPoints || scorePlayer2 >= maximumPoints && (scorePlayer2 - scorePlayer1) > 1) {
			return OPPONENT;
		}
		return null;
	}

	hidden function isWon() {
		var winning_sets = sets.size() / 2;
		var player_1_sets = getSetsWon(YOU);
		if(player_1_sets > winning_sets) {
			return YOU;
		}
		var player_2_sets = getSetsWon(OPPONENT);
		if(player_2_sets > winning_sets) {
			return OPPONENT;
		}
		return null;
	}

	function undo() {
		var set = getCurrentSet();
		if(set.getRallies().size() > 0) {
			winner = null;
			set.undo();
		}
	}

	function getActivity() {
		return Activity.getActivityInfo();
	}

	function getDuration() {
		var time = getActivity().elapsedTime;
		var seconds = time != null ? time / 1000 : 0;
		return new Time.Duration(seconds);
	}

	function getType() {
		return type;
	}

	function getSets() {
		return sets;
	}

	function hasEnded() {
		return winner != null;
	}

	function getTotalRalliesNumber() {
		var i = 0;
		var number = 0;
		while(i < sets.size() && sets[i] != null) {
			number += sets[i].getRalliesNumber();
			i++;
		}
		return number;
	}

	function getTotalScore(player) {
		var score = 0;
		for(var i = 0; i <= getCurrentSetIndex(); i++) {
			score = score + sets[i].getScore(player);
		}
		return score;
	}

	function getSetsWon(player) {
		var won = 0;
		for(var i = 0; i <= getCurrentSetIndex(); i++) {
			if(sets[i].getWinner() == player) {
				won++;
			}
		}
		return won;
	}

	function getWinner() {
		return winner;
	}

	function getServerTeam() {
		return getCurrentSet().getServerTeam();
	}

	function getServingCorner() {
		return getCurrentSet().getServingCorner();
	}

	function getReceivingCorner() {
		var serving_corner = getServingCorner();
		return OPPOSITE_CORNER[serving_corner];
	}

	function getPlayerIsServer() {
		var player_corner = getPlayerCorner();
		return player_corner == getServingCorner();
	}

	//methods used from perspective of player 1 (watch carrier)
	function getPlayerTeamIsServer() {
		return getServerTeam() == YOU;
	}

	function getPlayerCorner() {
		var current_set = getCurrentSet();
		//in singles, the player 1 (watch carrier) position only depends on the current score
		if(type == SINGLE) {
			var server = current_set.getServerTeam();
			var server_score = current_set.getScore(server);
			return server_score % 2 == 0 ? YOU_RIGHT : YOU_LEFT;
		}
		//in doubles, it's not possible to give the position using only the current score
		//remember that the one who serves changes each time the team gains the service (winning a rally while not serving)
		var beginner = current_set.getBeginner();
		var rallies = current_set.getRallies();
		//initialize the corner differently depending on which team begins the set and which player starts to serve
		//while the player 1 team (watch carrier) did not get a service, the position of the player depends on who has been configured to serve first (among the player and his teammate)
		var corner = beginner == YOU ? server ? YOU_RIGHT : YOU_LEFT : server ? YOU_LEFT : YOU_RIGHT;
		for(var i = 0; i < rallies.size(); i++) {
			var previous_rally = i > 0 ? rallies.get(i - 1) : beginner;
			var current_rally = rallies.get(i);
			if(previous_rally == current_rally && current_rally == YOU) {
				corner = corner == YOU_RIGHT ? YOU_LEFT : YOU_RIGHT;
			}
		}
		return corner;
	}
}
