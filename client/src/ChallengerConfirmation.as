package  
{
	/**
	 * ChallengerConfirmation.as
	 * 
	 * @author Hoten
	 */
	
	import fl.controls.Button;
	import fl.controls.TextArea;
	import flash.display.Sprite;
	
	public class ChallengerConfirmation extends Sprite
	{
		public var yes:Button;
		public var no:Button;
		public var ta:TextArea;
		
		public function ChallengerConfirmation() {
			ta = new TextArea();
			ta.width = 200;
			ta.height = 50;
			
			no = new Button();
			no.label = "No thanks."
			
			yes = new Button();
			yes.label = "Play!"
			yes.x = ta.width - yes.width;
			
			yes.y = no.y = ta.height + 5;
			
			addChild(ta);
			addChild(no);
			addChild(yes);
		}
	}
}