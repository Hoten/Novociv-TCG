package  
{
	/**
	 * WebpageLoader.as
	 * 
	 * Attempts a connection to a URL, and once connected, passes the data retrieved by the Loader to an external function.
	 * 
	 * @author Hoten
	 */
	
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
		
	public class WebpageLoader {
		
		private var loader:URLLoader;
		private var req:URLRequest;
		private var onComplete:Function;
		
		public function WebpageLoader(url:String, onComplete:Function) {
			this.onComplete = onComplete;
			loader = new URLLoader();
			req = new URLRequest(url);
			loader.addEventListener(Event.COMPLETE, function(e:Event) {
				onComplete(loader.data);
			});
		}
		
		public function load():void {
			loader.load(req);
		}
	}
}