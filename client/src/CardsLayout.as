package  
{
	/**
	 * CardsLayout.as
	 * 
	 * Card container. Automatically spreads cards out across a defined maximum width.
	 * Hovering mouse over card moves it to the top of the display list.
	 * Clicking on a card calls an external function, and passes that card to it.
	 * 
	 * @author Hoten
	 */
	
	import flash.display.Sprite;
	import flash.events.MouseEvent;

	public class CardsLayout extends Sprite
	{
		private static var MAX_IN_ROW:int = 20;
		private var cards:Vector.<Card>;
		private var maxWidth:int;
		private var onClickF:Function;
		private var spanMultipleRows:Boolean;
		
		public function CardsLayout(maxWidth:int, onClickF:Function, spanMultipleRows:Boolean = false ) {
			cards = new Vector.<Card>();
			this.maxWidth = maxWidth;
			this.onClickF = onClickF;
			this.spanMultipleRows = spanMultipleRows;
		}
		
		public function add(newCard:Card):void {
			cards.push(newCard);
			newCard.scaleX = newCard.scaleY = Main.CARD_SCALE;
			addChild(newCard);
			updateLayout();
			
			//add listeners
			
			newCard.addEventListener(MouseEvent.CLICK, function (e:MouseEvent) {
				if (!Card.viewingCard && !e.ctrlKey) onClickF(newCard);
			});
			
			newCard.addEventListener(MouseEvent.MOUSE_OVER, function (e:MouseEvent) {
				if (!Card.viewingCard) {
					updateLayout();
					setChildIndex(newCard, numChildren - 1);
				}
			});
			
			newCard.addEventListener(MouseEvent.MOUSE_OUT, function (e:MouseEvent) {
				if (!Card.viewingCard) updateLayout();
			});
		}
		
		public function remove(cardToRemove:Card):int {
			var index:int = cards.indexOf(cardToRemove);
			if (index != -1) {
				cards.splice(index, 1);
				removeChild(cardToRemove);
				updateLayout();
			}
			return index;
		}
		
		public function pop():void {
			if (cards.length) remove(cards[0]);
		}
		
		public function clear():void {
			cards.splice(0, cards.length);
			while (numChildren) removeChildAt(0);
		}
		
		public function size():int {
			return cards.length;
		}
		
		public function updateLayout():void {
			var size:int = cards.length;
			var numInRow:int = spanMultipleRows ? MAX_IN_ROW : size;
			var numColumns:int = spanMultipleRows ? Math.ceil(size / MAX_IN_ROW) : 1;
			var cardHeight:Number = Main.CARD_SCALE * Main.CARD_HEIGHT;
			for (var i:int = 0; i < size; i++) {
				var card:Card = cards[i];
				var x:int = i % numInRow;
				var y:int = i / numInRow;
				card.x = maxWidth / numInRow * x;
				if (spanMultipleRows) card.y = stage.stageHeight / numColumns * y;
				setChildIndex(card, numChildren - i - 1);
			}
		}
	}
}