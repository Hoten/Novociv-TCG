package  
{
	/**
	 * Chat.as
	 * 
	 * @author Hoten
	 */
	
	import fl.controls.Button;
	import fl.controls.List;
	import fl.controls.TextArea;
	import fl.controls.TextInput;
	import flash.display.Sprite;
	import hoten.serving.ServerMessage;
	
	public class Chat extends Sprite
	{
		public static const bufferHeightForGame:int = 125;
		public static const chatWidthForGame:int = 150;
		
		public var ta:TextArea;//text area
		public var ti:TextInput;//text input
		public var snd:Button;//send button
		public var ul:List;//user list
		
		public function Chat() {
			ta = new TextArea();
			ta.editable = false;
			ti = new TextInput();
			snd = new Button();
			snd.label = "Send";
			ul = new List();
			addChild(ta);
			addChild(ti);
			addChild(snd);
			addChild(ul);
			
			alpha = 0.8;
		}
		
		public function arrangeForLobby():void {
			const bufferSpace:int = 200;
			
			//set text area
			ta.width = stage.stageWidth - bufferSpace * 2 - ul.width;
			ta.x = bufferSpace;
			ta.height = stage.stageHeight - bufferSpace * 2;
			ta.y = bufferSpace;
			
			//set text input
			ti.width = ta.width;
			ti.x = ta.x;
			ti.y = ta.y + ta.height + 5;
			
			//set button
			snd.x = ti.x + ti.width + 5;
			snd.y = ti.y;
			snd.width = ul.width;
			
			//user list
			ul.x = ta.x + ta.width + 5;
			ul.y = ta.y;
			ul.height = ta.height;
			
			ta.text = "Welcome to the novociv trading card game. To challenge an opponent, double click a name on the right!\n\nPress '`' for fullscreen (to the left of 1 on your keyboard)\n\n";
		}
		
		public function arrangeForGame():void {
			snd.width = 50;
			
			ul.width = chatWidthForGame;
			ta.width = chatWidthForGame;
			ti.width = chatWidthForGame - snd.width - 5;
			
			//user list
			ul.x = stage.stageWidth - ul.width;
			ul.y = bufferHeightForGame;
			ul.height = 150;
			
			//set text area
			ta.x = ul.x;
			ta.height = stage.stageHeight - bufferHeightForGame * 2 - ti.height - ul.height - 15;
			ta.y = ul.y + ul.height + 5;
			
			//set text input
			ti.x = ta.x;
			ti.y = ta.y + ta.height + 5;
			
			//set button
			snd.x = ti.x + ti.width + 5;
			snd.y = ti.y;
			
			ta.text = "This is a private chat room for you and your opponent. Use it to orchestrate the game.\n\nNeed to move a card somewhere else, or create/delete a counter? Right click on it!\n\n";
		}
		
		public function append(line:String):void {
			//var max:Boolean = ta.verticalScrollPosition == ta.maxVerticalScrollPosition;
			ta.appendText(line + "\n");
			/*if (max) */ta.verticalScrollPosition = ta.maxVerticalScrollPosition;
		}
		
		public function removeFromUserList(s:String):void {
			for (var i:int = 0; i < ul.dataProvider.length; i++) {
				if (ul.getItemAt(i).label == s) ul.removeItemAt(i);
			}
		}
		
		public function addToUserList(s:String):void {
			ul.addItem( { label:s } );
		}
		
		public function sendMessage():void {
			if (ti.text.length != 0) {
				var msg:ServerMessage = new ServerMessage(2);
				msg.writeUTF(ti.text);
				msg.send();
				ti.text = "";
			}
		}
	}
}