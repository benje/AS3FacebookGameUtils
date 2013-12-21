/**
 *
 *	AS3 Facebook Game Utils - FBGU
 *  FbLoadingStatus.as
 *  Displays and manages a Loading Status bar when dynamically loading Facebook data.
 *
 *	@version 1 | July 2011
 *	@author Ben Reynhart / ben@mutantlabs.com
 * 	Dependencies: Facebook_library_v3.4_flash.swc
 *
 **/


package com.mutantlabs.fgu.views
{

	import com.facebook.views.Distractor;
	import com.greensock.*;
	import com.greensock.TweenMax;
	import com.greensock.events.LoaderEvent;
	import com.greensock.loading.*;
	import com.greensock.loading.display.*;
	import com.greensock.plugins.*;
	import com.mutantlabs.fgu.*;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;


	public class FGUStatusBar extends MovieClip
	{
		//Objects
		private var parentInstance:FBPairs;
		private var _loadingStatusMc:MovieClip  = new loadingStatusMc();
		private var _fbDist:Distractor;

		//Variables
		public var isActive:Boolean				= false;


		// ------------ CONSTRUCTOR --------------------------------------------- //

		public function FGUStatusBar(FGUClass:FacebookGameUtilsiOS, _fbdistractor:Boolean=true){

			//Init the loader
			initLoader(FGUClass, _fbdistractor);
		}

		//Setup vars and add to stage
		private function initLoader(FGU:FacebookGameUtilsiOS, fbdistractor1:Boolean):void
		{	
			//Add to stage
			_loadingStatusMc.x = FBPairs.STAGE_WIDTH/2;
			_loadingStatusMc.y = FBPairs.STAGE_HEIGHT/2;
			addChild(_loadingStatusMc);
			_loadingStatusMc.visible = false;

			//Add FB distractor animation if needed
			if(fbdistractor1){
				_fbDist = new Distractor();
				_loadingStatusMc.addChild(_fbDist);
				_fbDist.x = -250;
				_fbDist.y = -10;
			}

			//Add listeners to FacebookGameUtils class
			FGU.statusUpdateSignal.add(statusUpdateHandler);
			FGU.currentPhaseComplete.add(onPhaseCompleteHandler);
		}


		// ------------ EVENT HANDLER FROM FACEBOOKGAMEUTILS CLASS -------------- //


		//Handler for statusUpdateSignal
		private function statusUpdateHandler(statusStr:String):void
		{
			//Update status text
			updateText(statusStr);

		/*Depending on handler
		switch(statusStr)
		{
			case FacebookGameUtils.TXT_UPDT_LOGGING:
				break;
		}*/
		}


		//Handler triggered when current phase complete & fade out status bar (e.g. friends loaded)
		private function onPhaseCompleteHandler(stateName:String):void
		{
			//What state's do you want the loader to fade down on? 
			switch(stateName)
			{
				case FacebookGameUtilsiOS.STATE_LOADING:
					//If active
					if(isActive)
					{
						killMe();
					}
					break;
			}
		}


		// ------------ CONSTRUCTOR --------------------------------------------- //


		//Boot up the loader 
		public function bootUp(loadType2:String):void
		{
			//Set loading text
			if (loadType2 == "default"){
				_loadingStatusMc.loaderTxt.text = "LOADING FACEBOOK DATA";
			} else {
				_loadingStatusMc.loaderTxt.text = loadType2 as String;
			}

			TweenMax.to(_loadingStatusMc, 0.7, {autoAlpha:1});

			//Set active
			isActive = true;
		}


		//Update the loader text
		public function updateText(loaderString:String):void
		{
			//If updateText called and not active - bootup
			if(!isActive){
				bootUp(loaderString as String);
			} else if (isActive) {
				_loadingStatusMc.loaderTxt.text = loaderString as String;
			}
		}


		//Kill me function fades loader out
		public function killMe():void 
		{
			TweenMax.to(_loadingStatusMc, 0.7, {autoAlpha:0});

			isActive = false;
		}

		//---- HOUSEKEEPING ------------------------------------------------- //

		public function houseKeeping():void {

			//Remove the image
			if (this.contains(_loadingStatusMc)){
				removeChild(_loadingStatusMc);
				_loadingStatusMc = null
			}

		}

	}
}

