using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Math as Math;

class BeginnerView extends Ui.View {

	//! Load your resources here
	function onLayout(dc) {
		setLayout(Rez.Layouts.beginner(dc));
	}

	//! Restore the state of the app and prepare the view to be shown
	function onShow() {
	}

	//! Called when this View is removed from the screen. Save the
	//! state of your app here.
	function onHide() {
	}

}

class BeginnerViewDelegate extends Ui.BehaviorDelegate {

	function onKey(key) {
		if(key.getKey() == Ui.KEY_ENTER) {
			//begin match with random player
			var beginner = Math.rand() % 2 == 0 ? :player_1 : :player_2;
			match.begin(beginner);
			Ui.switchToView(new MatchView(), new MatchViewDelegate(), Ui.SLIDE_IMMEDIATE);
			return true;
		}
		return false;
	}

	function onNextPage() {
		//begin match with player 1 (watch carrier)
		match.begin(:player_1);
		Ui.switchToView(new MatchView(), new MatchViewDelegate(), Ui.SLIDE_IMMEDIATE);
		return true;
	}

	function onPreviousPage() {
		//begin match with player 2 (opponent)
		match.begin(:player_2);
		Ui.switchToView(new MatchView(), new MatchViewDelegate(), Ui.SLIDE_IMMEDIATE);
		return true;
	}

	function onBack() {
		//return to type screen
		Ui.switchToView(new TypeView(), new TypeViewDelegate(), Ui.SWIPE_LEFT);
		return true;
	}

}