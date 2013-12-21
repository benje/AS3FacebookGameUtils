/**
 *
 *	AS3 Facebook Game Utils - FBGU
 *  Helper class for using Facebook data (images, text, friendslist) in Flash games
 *
 *	@version 1 | July 2011
 *	@author Ben Reynhart / ben@mutantlabs.com
 * 	Dependencies: GraphAPI_Mobile_1_8_1.swc, team2p0.Preload, Greensock TweenLite, Signals, StageWebViewBridge.swc
 *
 **/

package com.mutantlabs.fgu {
	import com.mutantlabs.fgu.Settings;
	import flash.geom.Rectangle;
	import flash.media.StageWebView;
	import es.xperiments.media.StageWebViewBridge;
	import com.facebook.graph.*;
	import com.facebook.graph.FacebookMobile;
	import com.facebook.views.Distractor;
	import com.greensock.TweenLite;
	import com.team2p0.Preload;

	import flash.events.*;
	import flash.system.Security;
	import flash.utils.*;

	import org.osflash.signals.Signal;


	public class FacebookGameUtilsiOS extends EventDispatcher
	{
		// constants
		public static const API_KEY           	  : String = "XXXXXXXXXXXX";
		public static const PERMISSIONS		      : Object = {scope:"publish_stream, user_photos, user_status, friends_status,friends_photos"};
		public static const PERMISSIONS_M		  : Array  = new Array("publish_stream", "user_photos", "user_status", "friends_status", "friends_photos");
		public static const FB_REDIRECT_URL       : String = "http://apps.facebook.com/XXXXXXXXX/";
		public static const LOGGED_IN         	  : String = "loggedin";
		public static const LOGGED_IN_ON_FB   	  : String = "loggedinonfacebook";
		public static const LOGGED_OUT        	  : String = "loggedout";
		public static const LOGGED_OUT_ON_FB  	  : String = "loggedoutonfacebook";
		public static const REQ_MYDETAILS		  : String = "myDetails";
		public static const REQ_FRIENDSLIST		  : String = "myFriendsList";

		public static const TXT_UPDT_LOGGING	  : String = "LOGGING IN";
		public static const TXT_UPDT_GETTING_DATA : String = "RETRIEVING FRIEND DATA";
		public static const TXT_UPDT_LOADING_IMGS : String = "LOADING FRIEND'S IMAGES";
		public static const STATE_LOGIN			  : String = "Login";
		public static const STATE_RETRIEVE_PROFILE: String = "Retrieving data";
		public static const STATE_RETRIEVE_FRIENDS: String = "Retrieving data";
		public static const STATE_LOADING		  : String = "Loading data";

		//Variables
		private var topURL:String;
		public var _loggedState:String			= LOGGED_OUT;
		private var _isLoggedIn:Boolean			= false;
		private var _loggedInName:String		= "";
		private var _randFriendsAmount:Number;
		private var _preloader:Preload;

		//Data Objects
		private var _me:Object;
		private var _friendsList:Array;

		//Signals
		public var statusUpdateSignal:Signal 	= new Signal(String);
		public var currentPhaseComplete:Signal  = new Signal(String);

		public var loginCompleteSignal:Signal	= new Signal();
		public var friendsListRecieved:Signal 	= new Signal();
		public var friendsImagesLoaded:Signal 	= new Signal(Array);


		// ------------ CONSTRUCTOR --------------------------------------------- //

		public function FacebookGameUtilsiOS()	
		{
			//Use ExternalInterface to check if app is hosted on Facebook website or externally
//			topURL = ExternalInterface.call('top.location.toString');
			topURL = "www";
//			Security.loadPolicyFile("https://fbcdn-profile-a.akamaihd.net/crossdomain.xml");
//			Security.allowDomain("*");
//			Security.allowInsecureDomain("*");
		}


		// ------------ PUBLIC FUNCTIONS --------------------------------------- //


		/**
		 * Initialise Facebook connection - Required before any more
		 *
		 */	
		public function initFBConnection():void
		{	
			tracer("@@INFO@@ Initializing Facebook Connection");
			FacebookMobile.init(API_KEY, onInit);
			_loggedState = (topURL) ? LOGGED_OUT: LOGGED_OUT_ON_FB;
		}


		/**
		 * Get list of 'amount' random friends photos in an array
		 * @param amount
		 *
		 */	
		public function getRandomFriendsPhotos(amount:Number):void 
		{
			//trace("Getting random list of friends");
			_randFriendsAmount = amount;

			//If FriendsList empty, request it and listen for Signal to call function again
			if(!_friendsList)
			{
				handleFacebookRequest(REQ_FRIENDSLIST);
				friendsListRecieved.addOnce(getRandomFriendsPhotos);
				return;
			} 
			else 
			{
				var randomFriendsIds:Array = createRandomFriendIdArray(_friendsList);
				var randomFriendsPhotoUrls:Array = retrieveProfilePhotoURLs(randomFriendsIds);

				//Begin preloading photo URL's
				startPreloading(randomFriendsPhotoUrls);
			}
		}





		// ------------ FB DATA REQUESTS -------------------------------------- //


		/**
		 * Handles all Facebook data requests
		 * @param event
		 *
		 */	
		private function handleFacebookRequest(requestType:String):void
		{
			//Filter request type
			switch (requestType)
			{
				case REQ_MYDETAILS:
					FacebookMobile.api("/me",handleDetailsLoad);
					tracer("Requesting my details");

					//Send status update
					//statusUpdateSignal.dispatch(TXT_UPDT_GETTING_DATA);	
					break;

				case REQ_FRIENDSLIST:
					FacebookMobile.api('/me/friends', handleFriendsLoad);

					//Send status update
					statusUpdateSignal.dispatch(TXT_UPDT_GETTING_DATA);	
					break;
			}

		}





		// ------------ UTILITY FUNCTIONS ----------------------------------- //


		/**
		 * Create array of random friend's Id's
		 * @param entireFriendList
		 * @return
		 *
		 */	
		private function createRandomFriendIdArray(entireFriendList:Array):Array
		{
			//Grab correct number of random friend id's
			var _friendsListCopy:Array = entireFriendList.concat( );

			var _selectedFriends:Array = new Array();
			_selectedFriends = getRandomFriendsId(_friendsListCopy);

			return _selectedFriends;
		}


		/**
		 * Return correct number of random friend objects
		 * @param friends
		 * @return
		 *
		 */	
		private function getRandomFriendsId(friends:Array):Array 
		{
			var tmpArray:Array = [];
			var randArray:Array = randomizeArray(friends); //shuffle array

			//Populate tmpArray until amount of pairs total reached
			for(var i:Number = 0; i < _randFriendsAmount; i++){;

				//var friendId:Number = randArray[i] as Number;
				var idObject:Object;
				var nameObject:Object;

				//Isolate just the ID of random friends
				for (var n:String in randArray[i]){
					if (n == 'id'){		
						idObject = randArray[i][n];
					} else if (n == 'name'){
						nameObject = randArray[i][n];
					}
				}

				tmpArray.push(idObject); 
				randArray.splice(i, 1) // splice to remove dupes
			}

			return tmpArray;
		}


		/**
		 * Retrieves photo URLs for an array of user Id's and returns them in an Array
		 * @param userIds
		 * @return
		 *
		 */	
		private function retrieveProfilePhotoURLs(userIds:Array):Array
		{
			var profilePhotoURLArray:Array = new Array();
			var imgURL:String;

			for each (var userId:Object in userIds){
				imgURL = FacebookMobile.getImageUrl(String(userId), 'large');
				profilePhotoURLArray.push(imgURL);
				//trace(imgURL);
			}

			return profilePhotoURLArray;
		}


		// Login & Logout Methods
		public function login():void 
		{
			tracer("@@INFO@@ Login Called");

			//Send status update
			statusUpdateSignal.dispatch(TXT_UPDT_LOGGING);

			//setTimeout(Facebook.login, 200, loginHandler, opts);
			//Facebook.login(loginHandler, PERMISSIONS);
//			FacebookMobile.login(loginCallback, this.stage, [], webview);

			var webView:StageWebView = new StageWebView();
			webView.viewPort = new Rectangle(0, 0, Settings.STAGE_WIDTH, Settings.STAGE_HEIGHT );
			FacebookMobile.login(loginHandler, Settings.stage, PERMISSIONS_M, webView);
		}

		private function logout():void 
		{
			FacebookMobile.logout(logoutHandler);
		}

		//Repeater function for friendsList callback
		private function reload():void
		{

		}


		// ------------ PRELOAD FUNCTIONS --------------------------------- //


		//Pass assets to preload and add event listeners
		private function startPreloading(urlArray:Array):void
		{
			//trace("Photos URLS: "+urlArray);
			_preloader = new Preload(urlArray);
			_preloader.addEventListener("preloadProgress", onPreloadProgress);
			_preloader.addEventListener("preloadComplete", onPreloadComplete); 

			//Send status update
			statusUpdateSignal.dispatch(TXT_UPDT_LOADING_IMGS);
		}


		//TODO: preloading animation for patterns
		private function onPreloadProgress(event:Event):void
		{

		}


		/**
		 * onPreloadComplete - remove event listeners and parse returned image array to displayPatterns
		 * @param event
		 *
		 */		
		private function onPreloadComplete(event:Event):void
		{
			//Remove event listeners
			_preloader.removeEventListener("preloadProgress", onPreloadProgress);
			_preloader.removeEventListener("preloadComplete", onPreloadComplete);

			//Dispatch Signal
			friendsImagesLoaded.dispatch(_preloader.objects);
			currentPhaseComplete.dispatch(STATE_LOADING);
		}



		// ------------ FB CONNECTION AND LOGIN HANDLERS ------------------------ //


		/**
		 * Callback from Init
		 * @param result
		 * @param fail
		 *
		 */	
		private function onInit(result:Object, fail:Object):void
		{
			if ( result != null) 
			{
				_loggedState = (topURL) ? LOGGED_IN : LOGGED_IN_ON_FB;
				//_loggedState = LOGGED_IN;
				tracer("@@INFO@@ Already logged in - no need to login");
			} else 
			{
				_loggedState = LOGGED_OUT;
				tracer("@@INFO@@ Not logged in - need to login");
			}
		}


		/**
		 * Handles login / init callback from Facebook API
		 * @param response
		 * @param fail
		 *
		 */	
		private function loginHandler(response:Object, fail:Object):void 
		{
			tracer("loginHandler Callback")
			
			//If successfull update loggedState, request profile data and dispatch to FbLoadingStatusBar
			if (response) 
			{
				tracer("@@INFO@@ Logged in!");
				_loggedState = (topURL) ? LOGGED_IN : LOGGED_IN_ON_FB;

				//Collect personal details
				handleFacebookRequest(REQ_MYDETAILS);

				//Send status update
				statusUpdateSignal.dispatch(TXT_UPDT_LOGGING);
				currentPhaseComplete.dispatch(STATE_LOGIN);
			}	
			else if ( response == null && !topURL)
			{
				tracer("@@INFO@@ Accessed via Facebook website - redirecting to inline login");
//				ExternalInterface.call("redirect", API_KEY, "publish_stream, user_photos, user_status, friends_status,friends_photos", FB_REDIRECT_URL);
			} 
		/*else
		{
			setTimeout( Facebook.login, 200, loginHandler, ['user_photos', 'publish_stream'] );
		}*/
		}



		// ------------ EVENT HANDLERS ------------------------------------------ //

		private function logoutHandler(response:Object):void
		{
			tracer("@@INFO@@ Logged Out");
			_loggedState = (topURL) ? FacebookGameUtilsiOS.LOGGED_OUT : FacebookGameUtilsiOS.LOGGED_OUT_ON_FB;
		}


		//Handler for user profile details
		private function handleDetailsLoad(response:Object, fail:Object):void 
		{
			if(response){
				_me = response;
				tracer("Successfully fetched your profile data");

				//Send status update
				loginCompleteSignal.dispatch();
				currentPhaseComplete.dispatch(STATE_RETRIEVE_PROFILE);
			}
			else if (fail){
				tracer("Could not fetch details: " + fail);
			}
		}


		//Handler for friends list details
		private function handleFriendsLoad(response:Object, fail:Object):void 
		{
			if(response){
				tracer("Successfully fetched friends list");
				_friendsList = response as Array;

				//Dispatch event and send statusUpdate
				friendsListRecieved.dispatch(_randFriendsAmount); //pass in amount to getRandomFriendsPhotos
				currentPhaseComplete.dispatch(STATE_RETRIEVE_FRIENDS);	
			} 
			else if (fail){
				tracer("Could not fetch details: " + fail);
				return;
			}
		}



		// ------------ GETTERS AND SETTERS ------------------------------------- //


		/**
		 * Simple getter to check if loggedIn
		 * @return
		 *
		 */	
		public function get isLoggedIn():Boolean
		{
			if(_loggedState == LOGGED_IN || _loggedState == LOGGED_IN_ON_FB){
				_isLoggedIn = true;
			} else {
				_isLoggedIn = false;
			}
			return _isLoggedIn;
			tracer("Is logged in returned: "+_isLoggedIn);
		}


		// ------------ CLASS UTILITIES ------------------------------------- //


		/**
		 * Randomize array
		 * @param array
		 * @return
		 *
		 */		
		private function randomizeArray(array:Array):Array 
		{
			var newArray:Array = new Array();
			while(array.length > 0){
				var obj:Array = array.splice(Math.floor(Math.random()*array.length), 1);
				newArray.push(obj[0]);
			}
			return newArray;
		}

		//Tracer echos any trace commands to appropriate place
		private function tracer( msg:String ):void
		{
			FBPairs.tracer( msg );
		}




	}

}

