package  
{
	/**
	 * CardFactory.as
	 * 
	 * Caches card graphics and provides a simple way to obtain a card object when gfx retrival could take up to a couple of seconds
	 * 
	 * @author Hoten
	 */
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;	
	
	public class CardFactory 
	{
		public static var ins:CardFactory;
		
		private var cardGfx:Array;
		
		public function CardFactory() {
			cardGfx = [];
			[Embed(source = "back.jpg")]
			var back:Class;
			cardGfx["back.jpg"] = (new back() as Bitmap).bitmapData;
			ins = this;
		}
		
		public function getCard(cardName:String, foil:Boolean):Card {
			var bmd:BitmapData;
			var cache:BitmapData = cardGfx[cardName];
			var card:Card = new Card(cardName, foil);
			if (cache == null) {
				var loader:Loader = new Loader();
				loader.load(new URLRequest("http://forums.novociv.org/cards/images/cardimages/" + cardName));
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function onComplete (e:Event) {
					loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onComplete);
					var bitmap:Bitmap = e.target.content;
					
					//the bitmap comes to us with no transparency in the corners. instead it has white pixels where we want
					//transparent pixels to be. First we must create a new, transparent bitmap, then copy over the pixels.
					//because the orignal white pixels aren't a solid white (i.e. they differ slightly), we can't use the
					//built in BitmapData.threshold(). So we must loop through all the pixels, but only look at the corners.
					//opening up a card in a graphics editor shows that the corners are 17x17, so we only look at the pixels
					//in those corner squares. We query the pixel, and just look at the blue byte. if it is high, it is most
					//definetely not black and must be a white-ish pixel, and we set it to a transparent pixel.
					
					var bmd:BitmapData = new BitmapData(bitmap.bitmapData.width, bitmap.bitmapData.height);
					bmd.copyPixels(bitmap.bitmapData, new Rectangle(0, 0, bmd.width, bmd.height), new Point(0, 0));
					const threshold:int = 17;
					for (var x:int = 0; x < bmd.width; x++) {
						if (x == threshold) x = bmd.width - threshold;
						for (var y:int = 0; y < bmd.height; y++) {
							if (y == threshold) y = bmd.height - threshold;
							var curP:uint = bmd.getPixel(x, y);
							if ((curP & 0xff) > 0x66) bmd.setPixel32(x, y, 0);
						}
					}
					bitmap.bitmapData = bmd;
					cardGfx[cardName] = bmd;
					
					//remove the placeholder gfx
					while (card.numChildren) card.removeChildAt(0);
					
					card.addChild(bitmap);
				});
				
				//add placeholder image
				card.addChild(new Bitmap(cardGfx["back.jpg"]));
			}else {
				card.addChild(new Bitmap(cache));
			}
			return card;
		}
	}
}