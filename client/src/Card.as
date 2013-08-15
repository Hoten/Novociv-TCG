package  
{
	/**
	 * Card.as
	 * 
	 * Every card object can be zoomed in on. Zooming hides the target card, and creates a new one in the middle of the screen
	 * at normal scale. Tapping a card rotates it w/ an animation. If a card is a foil, it will have a golden border and an
	 * increased contrast.
	 * 
	 * @author Hoten
	 */
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.ColorMatrixFilter;
	import flash.filters.GlowFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;

	public class Card extends Sprite
	{
		
		private static var glowFilter:GlowFilter = new GlowFilter(0xFFD700, 1, 16, 16);
		public static var viewingCard:Boolean;
		public static var currentCard:Card;
		public static var bigCard:Card;
		
		private var theta:Number, targetTheta:Number, rotationSpeed:Number, isRotating:Boolean;
		private var cardName:String;
		
		public function Card(cardName:String, isFoil:Boolean) {
			this.cardName = cardName;
			foil = isFoil;
			theta = 0;
			
			//add listeners
			
			addEventListener(MouseEvent.MOUSE_WHEEL, function (e:MouseEvent) {
				if (!viewingCard && e.delta > 0) toggleSize();
			});
			
			addEventListener(MouseEvent.CLICK, function (e:MouseEvent) {
				if (!viewingCard && e.ctrlKey) toggleSize();
			});
		}
		
		public function getCardName():String {
			return cardName;
		}
		
		public function get foil():Boolean {
			return filters.length != 0;
		}
		
		public function set foil(isFoil:Boolean):void {
			if (isFoil) {
				var matrix:Array = [];
				matrix = matrix.concat([1.5, 0, 0, 0, -40]); // red
				matrix = matrix.concat([0, 1.5, 0, 0, -40]); // green
				matrix = matrix.concat([0, 0, 1.5, 0, -40]); // blue
				matrix = matrix.concat([0, 0, 0, 1, 0]); // alpha
				var tint:ColorMatrixFilter = new ColorMatrixFilter(matrix);			
				filters = [tint, glowFilter];
			}else {
				filters = [];
			}
		}
		
		public function set tap(isTapped:Boolean):void {
			targetTheta = isTapped ? 90 : 0;
			rotationSpeed = isTapped ? 10 : -10;
			if (!isRotating) {
				stage.addEventListener(Event.ENTER_FRAME, function onFrame(e:Event) {
					theta += rotationSpeed;
					rotateAroundCenter(rotationSpeed);
					if (theta == targetTheta) {
						isRotating = false;
						stage.removeEventListener(Event.ENTER_FRAME, onFrame);
					}
				});
			}
			isRotating = true;
		}
		
		private function rotateAroundCenter(angleDegrees:Number):void {
			var matrix:Matrix = transform.matrix;
			var rect:Rectangle = getBounds(parent);
			var dx:Number = rect.left + (rect.width / 2);
			var dy:Number = rect.top + (rect.height / 2);
			matrix.translate( -dx, -dy);
			matrix.rotate((angleDegrees / 180) * Math.PI);
			matrix.translate(dx, dy);
			transform.matrix = matrix;
		}
		
		private function toggleSize():void {
			if (viewingCard) {
				viewingCard = false;
				currentCard.visible = true;
				if (bigCard != null) stage.removeChild(bigCard);
			}else if (!viewingCard) {
				currentCard = this;
				currentCard.visible = false;
				viewingCard = true;
				bigCard = CardFactory.ins.getCard(currentCard.getCardName(), currentCard.foil);
				
				bigCard.addEventListener(MouseEvent.CLICK, function (e:MouseEvent) {
					if (e.ctrlKey || viewingCard) toggleSize();
				});
				bigCard.addEventListener(MouseEvent.MOUSE_WHEEL, function (e:MouseEvent) {
					if (e.delta < 0 ) toggleSize();
				});				
				
				bigCard.x = stage.stageWidth / 2 - Main.CARD_WIDTH / 2;
				bigCard.y = stage.stageHeight / 2 - Main.CARD_HEIGHT / 2;
				stage.addChild(bigCard);
			}
		}
		
		//when the card is tapped and thus the matrix rotated, the x value is wrong.
		//I tested out the rotation code with regular sprites that i drew a rectangle on,
		//and the x was correct on that. So i think the bitmap child (the actually card gfx)
		//is throwing it off. here's some hacks to fix it.
		override public function get x():Number {
			return theta == 0 ? super.x : (super.x + width);
		}
		
		override public function set x(_x:Number):void {
			super.x = (theta == 0 ? _x : (_x - width));
		}
		
		override public function get width():Number {
			return theta == 0 ? super.width : -super.width;
		}
		
	}

}