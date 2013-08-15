package  
{
	/**
	 * GameUI.as
	 * 
	 * @author Hoten
	 */
	
	import fl.controls.Button;
	import flash.display.Sprite;
	
	public class GameUI extends Sprite
	{
		public var search:Button;
		public var draw:Button;
		public var shuffle:Button;
		
		public function GameUI() {
			search = new Button();
			draw = new Button();
			shuffle = new Button();
			
			search.label = "Search deck";
			draw.label = "Draw card";
			shuffle.label = "Shuffle deck";
			
			addChild(search);
			addChild(draw);
			addChild(shuffle);
		}
		
		public function arrangeFor(isPlayer1:Boolean):void {
			search.x = draw.x = shuffle.x = stage.stageWidth - (Chat.chatWidthForGame + search.width) / 2;
			if (isPlayer1) {
				draw.y = stage.stageHeight - Chat.bufferHeightForGame + 5;
				shuffle.y = draw.y + draw.height + 10;
				search.y = shuffle.y + shuffle.height + 10;
			}else {
				draw.y = 5;
				shuffle.y = draw.y + draw.height + 10;
				search.y = shuffle.y + shuffle.height + 10;
			}
		}
	}
}